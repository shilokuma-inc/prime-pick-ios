#!/usr/bin/env python3
"""App Store の名前・サブタイトル・説明文・キーワード・プロモーションテキスト・最新情報・URL・審査メモを App Store Connect に反映する。

`AppStore/metadata/<言語>.json` と `AppStore/metadata/shared.json` を読み、
対象バージョンの言語ごとに書き込む。名前とサブタイトルはバージョンではなくアプリ情報（`appInfoLocalizations`）に
書き込む（どちらも編集できるのは、次のバージョンを準備している間だけ）。
審査メモ（App Review に関する情報のメモ）は言語によらない 1 つの文面で、`AppStore/metadata/review.json` から
対象バージョンの `appStoreReviewDetails` に書き込む。連絡先とデモアカウントは扱わない（リポジトリが public なので）。

    python3 Tools/upload_metadata.py            # 反映する
    python3 Tools/upload_metadata.py --dry-run  # 現在値との差分だけ出す
    python3 Tools/upload_metadata.py --check    # App Store Connect につながず、手元のファイルだけ検査する
    python3 Tools/upload_metadata.py --export   # App Store Connect の現在値を AppStore/metadata/*.json に書き出す

認証は App Store Connect API Key（.p8）。次の環境変数でも渡せる。

    APP_STORE_CONNECT_KEY_ID / APP_STORE_CONNECT_ISSUER_ID / APP_STORE_CONNECT_PRIVATE_KEY_PATH

触るのは **編集できる状態のバージョンだけ**。審査中や配信済みのバージョンは対象にしない。
JSON に書いていない項目（例: 省略した promotionalText）は App Store Connect 側の値をそのまま残す。
最新情報（whatsNew）はバージョンごとの文言なので、JSON の `whatsNew.version` が反映先のバージョンと
一致するときだけ書き込む（前のバージョンの文言を次のバージョンに載せてしまわないため）。

`--export` は逆向きで、App Store Connect の現在値を JSON に書き出す。公開中の文言を正として
リポジトリに取り込むとき（初回）や、App Store Connect 側で直接編集した内容を取り込むときに使う。
現在値が無い言語・項目は書かず、その旨を出力する（勝手に説明文を作らない）。
最新情報は、書き出し元のバージョンの番号を `whatsNew.version` に入れて書く。審査メモは `review.json` に書く。

PyJWT が要る（--check では不要）: `python3 -m pip install pyjwt cryptography`
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import sys
import urllib.parse
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from app_store_config import ROOT, Language, bundle_id, languages, parse_list

METADATA_DIR = ROOT / "AppStore" / "metadata"

#: 言語によらない値をまとめたファイル
SHARED_FILE = "shared.json"

#: App Store Connect 側の上限。超えると反映時に弾かれるので、手元で先に落とす。
LIMITS = {
    "description": 4000,
    "keywords": 100,
    "promotionalText": 170,
    "whatsNew": 4000,
}

#: アプリ情報（`appInfoLocalizations`）に書く項目と上限。どちらも省略できる（省略すると App Store Connect 側の値を残す）
INFO_LIMITS = {
    "name": 30,
    "subtitle": 30,
}

#: 言語を追加したアプリ情報に、主言語から写す項目（空のままだと審査に出せない）
INFO_COPIED_FROM_PRIMARY = ("privacyPolicyUrl", "privacyChoicesUrl")

#: 審査メモ（App Review に関する情報のメモ）のファイル。言語によらない 1 つの文面を `notes` に書く
REVIEW_FILE = "review.json"

#: 審査メモの上限（App Store Connect の画面の上限）
REVIEW_NOTES_LIMIT = 4000


def find_emoji(value: str) -> list[str]:
    """絵文字（U+10000 以降の文字。🟩 など）。App Store Connect が INVALID_CHARACTERS で弾く（#542）。
    ■（U+25A0）のような記号は通る"""
    return sorted({character for character in value if ord(character) > 0xFFFF})


def load_shared(directory: Path) -> tuple[dict[str, str], list[str]]:
    path = directory / SHARED_FILE
    if not path.is_file():
        return {}, [f"{path} がありません"]
    raw = json.loads(path.read_text(encoding="utf-8"))
    problems = []
    attributes = {}
    # supportUrl は審査で実際に開かれるので必須。marketingUrl は任意
    for key, required in (("supportUrl", True), ("marketingUrl", False)):
        value = raw.get(key)
        if isinstance(value, str) and value.strip():
            # テンプレートの仮の値（TODO:）は形を問わず、反映の前の TODO: の検査で止める
            parsed = urllib.parse.urlparse(value)
            try:
                # `https://example.com:abc` のような不正なポート・範囲外のポートは、ここで ValueError になる
                parsed.port
                valid_port = True
            except ValueError:
                valid_port = False
            if "TODO:" not in value and not (parsed.scheme == "https" and parsed.hostname and valid_port):
                problems.append(f"{path}: {key} は https:// で始まる URL にしてください（ホスト名も要る）")
            attributes[key] = value
        elif required:
            problems.append(f"{path}: {key} がありません")
    return attributes, problems


def load(directory: Path, target: Language, shared: dict[str, str]) -> tuple[dict[str, str] | None, dict[str, str], str | None, list[str]]:
    """1 言語ぶんの書き込む値（バージョン・アプリ情報）と、最新情報の対象バージョンを読む。問題があれば値の代わりに理由を返す。"""
    path = directory / f"{target.language}.json"
    if not path.is_file():
        return None, {}, None, [f"{path} がありません"]
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return None, {}, None, [f"{path} が JSON として読めません: {error}"]

    problems: list[str] = []
    attributes: dict[str, str] = {}

    # 名前・サブタイトルは省略できる。null や空文字は書き損じなので、省略と同じには扱わない
    info_attributes: dict[str, str] = {}
    for field, limit in INFO_LIMITS.items():
        if field not in raw:
            continue
        value = raw[field]
        if not (isinstance(value, str) and value.strip()):
            problems.append(f"{path}: {field} が空です（使わないなら項目ごと消す）")
        elif value != value.strip():
            problems.append(f"{path}: {field} の前後に空白があります")
        elif any(character.isspace() and character != " " for character in value):
            # フランス語の「?」の前の細い空白（U+202F）など。App Store Connect が INVALID_CHARACTERS で弾く（#540）
            problems.append(f"{path}: {field} に普通の空白（U+0020）以外の空白があります")
        elif len(value) > limit:
            problems.append(f"{path}: {field} が {len(value)} 字あります（上限 {limit} 字）")
        else:
            info_attributes[field] = value

    description = raw.get("description")
    if isinstance(description, str) and description.strip():
        attributes["description"] = description
    else:
        problems.append(f"{path}: description がありません")

    keywords = raw.get("keywords")
    if isinstance(keywords, list) and keywords:
        # App Store Connect にはカンマ区切りの 1 本の文字列として渡す。
        # 区切りのあとに空白を入れると、そのぶん 100 字の枠を食うので詰めて繋ぐ。
        # null や空文字を str() で "None" や空の区切りにしてしまわないよう、空でない文字列だけを許す
        if all(isinstance(keyword, str) and keyword.strip() for keyword in keywords):
            attributes["keywords"] = ",".join(keyword.strip() for keyword in keywords)
        else:
            problems.append(f"{path}: keywords に空の要素か文字列以外の要素があります")
    else:
        problems.append(f"{path}: keywords がありません（配列で書く）")

    promotional_text = raw.get("promotionalText")
    if promotional_text is not None:
        if isinstance(promotional_text, str) and promotional_text.strip():
            attributes["promotionalText"] = promotional_text
        else:
            problems.append(f"{path}: promotionalText が空です（使わないなら項目ごと消す）")

    whats_new_version = None
    # 省略（キーが無い）と null を分ける。null は書き損じなので、省略と同じには扱わない
    if "whatsNew" in raw:
        whats_new = raw["whatsNew"]
        version = whats_new.get("version") if isinstance(whats_new, dict) else None
        text = whats_new.get("text") if isinstance(whats_new, dict) else None
        if not (isinstance(version, str) and version.strip() and isinstance(text, str) and text.strip()):
            problems.append(f"{path}: whatsNew は {{\"version\": \"2.1.0\", \"text\": \"…\"}} の形で書く（使わないなら項目ごと消す）")
        else:
            attributes["whatsNew"] = text
            whats_new_version = version

    for field, limit in LIMITS.items():
        value = attributes.get(field, "")
        if len(value) > limit:
            problems.append(f"{path}: {field} が {len(value)} 字あります（上限 {limit} 字）")

    for field, value in {**info_attributes, **attributes}.items():
        emoji = find_emoji(value)
        if emoji:
            problems.append(f"{path}: {field} に絵文字があります（{' '.join(emoji)}）")

    if problems:
        return None, {}, None, problems
    return {**attributes, **shared}, info_attributes, whats_new_version, []


def load_review(directory: Path) -> tuple[str | None, list[str]]:
    """審査メモ（`review.json` の `notes`）を読む。ファイルが無ければ None（App Store Connect 側の値を残す）。"""
    path = directory / REVIEW_FILE
    if not path.is_file():
        return None, []
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        return None, [f"{path} が JSON として読めません: {error}"]
    notes = raw.get("notes") if isinstance(raw, dict) else None
    if not (isinstance(notes, str) and notes.strip()):
        return None, [f"{path}: notes が空です（使わないならファイルごと消す）"]

    problems = []
    if len(notes) > REVIEW_NOTES_LIMIT:
        problems.append(f"{path}: notes が {len(notes)} 字あります（上限 {REVIEW_NOTES_LIMIT} 字）")
    # 審査メモで弾かれるかは確かめていないが、掲載文と同じく絵文字は使わない
    emoji = find_emoji(notes)
    if emoji:
        problems.append(f"{path}: notes に絵文字があります（{' '.join(emoji)}）")
    return (None, problems) if problems else (notes, [])


def describe_changes(current: dict, new: dict[str, str]) -> list[str]:
    """現在値から変わる項目を、人が読める形で返す。長い文章は行単位の差分にする。"""
    lines: list[str] = []
    for field, value in new.items():
        before = current.get(field) or ""
        if before == value:
            continue
        if "\n" in before or "\n" in value:
            lines.append(f"    {field}:")
            diff = difflib.unified_diff(before.splitlines(), value.splitlines(), lineterm="", n=1)
            lines.extend(f"      {line}" for line in list(diff)[2:])
        else:
            lines.append(f"    {field}: {before or '（空）'} → {value}")
    return lines


def _load_comment(path: Path) -> list[str] | None:
    """既存ファイルの `_comment`（運用メモ）は、現在値で上書きしても残す。"""
    if not path.is_file():
        return None
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return None
    comment = raw.get("_comment")
    return comment if isinstance(comment, list) else None


def _write_json(path: Path, body: dict) -> None:
    comment = _load_comment(path)
    payload = {"_comment": comment, **body} if comment else body
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def _exported_length(field: str, value: object) -> int:
    """書き出した値の、App Store Connect 上の文字数（keywords はカンマ込み、whatsNew は本文）。"""
    if field == "keywords" and isinstance(value, list):
        return len(",".join(value))
    if field == "whatsNew" and isinstance(value, dict):
        return len(value.get("text", ""))
    return len(value) if isinstance(value, str) else 0


def export(directory: Path, targets: list[Language], available: dict[str, dict], version_string: str,
           info_available: dict[str, dict] | None = None) -> int:
    """App Store Connect の現在値を `<言語>.json` と `shared.json` に書き出す。

    `info_available` はアプリ情報（`appInfoLocalizations`）のロケール → 現在値で、名前・サブタイトルを書き出すのに使う。

    書き出した言語の数を返す。現在値が無い言語・項目は書かずに報告だけする。
    """
    directory.mkdir(parents=True, exist_ok=True)
    written = 0
    missing: list[str] = []
    shared_values: dict[str, dict[str, str]] = {}

    for target in targets:
        label = f"{target.language} → {target.store_locale}"
        localization = available.get(target.store_locale)
        if localization is None:
            missing.append(f"{label}: {version_string} にこの言語がありません")
            continue
        attributes = localization["attributes"]

        body: dict[str, object] = {}
        info = (info_available or {}).get(target.store_locale, {}).get("attributes", {})
        for field in INFO_LIMITS:
            value = info.get(field) or ""
            if value.strip():
                body[field] = value
        description = attributes.get("description") or ""
        keywords = attributes.get("keywords") or ""
        promotional_text = attributes.get("promotionalText") or ""
        whats_new = attributes.get("whatsNew") or ""
        if description.strip():
            body["description"] = description
        else:
            missing.append(f"{label}: description が空です")
        if keywords.strip():
            body["keywords"] = [keyword.strip() for keyword in keywords.split(",") if keyword.strip()]
        else:
            missing.append(f"{label}: keywords が空です")
        if promotional_text.strip():
            body["promotionalText"] = promotional_text
        if whats_new.strip():
            body["whatsNew"] = {"version": version_string, "text": whats_new}

        for key in ("supportUrl", "marketingUrl"):
            value = attributes.get(key) or ""
            if value.strip():
                shared_values.setdefault(key, {})[target.language] = value

        path = directory / f"{target.language}.json"
        _write_json(path, body)
        written += 1
        counts = " / ".join(f"{field} {_exported_length(field, value)} 字" for field, value in body.items())
        print(f"  {label}: {path} に書き出し（{counts or '値なし'}）")

    # URL は言語によらない前提なので shared.json に 1 つだけ持つ。言語で違っていたら最初の言語の値を採り、報告する
    shared: dict[str, str] = {}
    for key, values in shared_values.items():
        distinct = sorted(set(values.values()))
        if len(distinct) > 1:
            details = ", ".join(f"{language}: {value}" for language, value in values.items())
            missing.append(f"shared.json: {key} が言語で違います（{details}）。先頭の言語の値を書きました")
        shared[key] = next(iter(values.values()))
    if "supportUrl" not in shared:
        missing.append("shared.json: supportUrl がどの言語にもありません（必須なので手で埋めてください）")
    if shared:
        shared_path = directory / SHARED_FILE
        _write_json(shared_path, shared)
        print(f"  共通: {shared_path} に書き出し（{', '.join(shared)}）")

    if missing:
        print("現在値が無い項目（JSON には書いていません）:")
        for line in missing:
            print(f"  - {line}")
    return written


def export_review_notes(directory: Path, detail: dict | None) -> None:
    """審査メモの現在値を `review.json` に書き出す。現在値が無ければ書かずに報告する。"""
    notes = ((detail or {}).get("attributes") or {}).get("notes") or ""
    if not notes.strip():
        print("  審査メモ: 現在値が無いので書き出しません")
        return
    path = directory / REVIEW_FILE
    _write_json(path, {"notes": notes})
    print(f"  審査メモ: {path} に書き出し（notes {len(notes)} 字）")


def make_client(args: argparse.Namespace, dry_run: bool):
    """認証情報がそろっているか確かめてから App Store Connect のクライアントを作る。"""
    missing_key = [
        name for name, value in
        [("--key-id", args.key_id), ("--issuer-id", args.issuer_id), ("--private-key", args.private_key)]
        if not value
    ]
    if missing_key:
        raise SystemExit(f"認証情報が足りません: {', '.join(missing_key)}")

    from app_store_connect import AppStoreConnect

    return AppStoreConnect(args.key_id, args.issuer_id, Path(args.private_key).read_text(), dry_run=dry_run)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--metadata-dir", type=Path, default=METADATA_DIR, help="<ここ>/<言語>.json を読む")
    parser.add_argument("--languages", help="対象の言語（カンマ区切り）。省略すると全言語")
    parser.add_argument("--bundle-id", help="省略すると project.pbxproj から読む")
    parser.add_argument("--app-version", help="反映先のバージョン。省略すると編集できるバージョンを自動で選ぶ")
    parser.add_argument("--key-id", default=os.environ.get("APP_STORE_CONNECT_KEY_ID"))
    parser.add_argument("--issuer-id", default=os.environ.get("APP_STORE_CONNECT_ISSUER_ID"))
    parser.add_argument(
        "--private-key",
        type=Path,
        default=os.environ.get("APP_STORE_CONNECT_PRIVATE_KEY_PATH"),
        help="App Store Connect API Key の .p8",
    )
    parser.add_argument(
        "--missing-locales",
        choices=("fail", "skip", "create"),
        default="fail",
        help="App Store Connect にその言語が無いときの扱い。"
             "fail: 止める（既定） / skip: 飛ばす / create: その言語を追加してから反映する",
    )
    parser.add_argument("--check", action="store_true",
                        help="App Store Connect につながず、手元のファイルの欠損と文字数だけ見る")
    parser.add_argument("--dry-run", action="store_true", help="何も書き換えず、現在値との差分だけ出す")
    parser.add_argument("--export", action="store_true",
                        help="App Store Connect の現在値を --metadata-dir の JSON に書き出す（App Store Connect には書き込まない）")
    args = parser.parse_args()

    if args.check and args.export:
        raise SystemExit("--check と --export は同時に指定できません")

    targets = languages(parse_list(args.languages))

    if args.export:
        # 取り込みが目的なので、手元の JSON が無くても・壊れていても止めない
        client = make_client(args, dry_run=True)
        app = client.find_app(args.bundle_id or bundle_id())
        version = client.find_version(app["id"], args.app_version)
        version_string = version["attributes"]["versionString"]
        print(f"取り込み元: {app['attributes']['name']} {version_string} "
              f"({version['attributes']['appStoreState']})")
        app_info = client.find_app_info(app["id"], editable=False)
        info_available = client.app_info_localization_entries(app_info["id"]) if app_info else {}
        written = export(args.metadata_dir, targets, client.localization_entries(version["id"]), version_string,
                         info_available)
        export_review_notes(args.metadata_dir, client.review_detail(version["id"]))
        print(f"書き出し: {written} 言語")
        return 0

    shared, problems = load_shared(args.metadata_dir)
    review_notes, review_problems = load_review(args.metadata_dir)
    problems.extend(review_problems)
    entries: list[tuple[Language, dict[str, str]]] = []
    #: 言語 → アプリ情報に書く名前・サブタイトル（書いてある言語だけ）
    info_entries: dict[str, dict[str, str]] = {}
    whats_new_versions: dict[str, str] = {}
    for target in targets:
        attributes, info_attributes, whats_new_version, issues = load(args.metadata_dir, target, shared)
        problems.extend(issues)
        if attributes:
            entries.append((target, attributes))
        if info_attributes:
            info_entries[target.language] = info_attributes
        if whats_new_version:
            whats_new_versions[target.language] = whats_new_version
    if problems:
        raise SystemExit("\n".join(problems))

    # テンプレートの仮の文言（TODO:）が残ったまま App Store Connect に書き込まない
    placeholders = [
        f"{target.language}.{field}" for target, attributes in entries
        for field, value in {**info_entries.get(target.language, {}), **attributes}.items() if "TODO:" in value
    ] + [
        f"{language}.whatsNew.version" for language, version in whats_new_versions.items() if "TODO:" in version
    ]
    if review_notes and "TODO:" in review_notes:
        placeholders.append(f"{REVIEW_FILE} の notes")
    if placeholders and not args.check:
        raise SystemExit(f"テンプレートの仮の文言（TODO:）が残っています: {', '.join(placeholders)}")

    if args.check:
        if placeholders:
            print(f"注意: テンプレートの仮の文言（TODO:）が残っています: {', '.join(placeholders)}")
        for target, attributes in entries:
            values = {**info_entries.get(target.language, {}), **attributes}
            counts = " / ".join(
                f"{field} {len(values[field])} 字" for field in (*INFO_LIMITS, *LIMITS) if field in values
            )
            version_note = (f"（whatsNew は {whats_new_versions[target.language]} 向け）"
                            if target.language in whats_new_versions else "")
            print(f"  {target.language}: {counts}{version_note}")
        if review_notes is not None:
            print(f"  審査メモ: notes {len(review_notes)} 字")
        print(f"問題なし: {len(entries)} 言語")
        return 0

    client = make_client(args, dry_run=args.dry_run)

    app = client.find_app(args.bundle_id or bundle_id())
    version = client.find_version(app["id"], args.app_version)
    version_string = version["attributes"]["versionString"]
    print(f"対象: {app['attributes']['name']} {version_string} "
          f"({version['attributes']['appStoreState']})")
    if args.dry_run:
        print("--dry-run: App Store Connect には何も書き込みません")

    # 最新情報は、書いてあるバージョンが反映先と一致する言語だけに入れる
    for target, attributes in entries:
        whats_new_version = whats_new_versions.get(target.language)
        if "whatsNew" in attributes and whats_new_version != version_string:
            del attributes["whatsNew"]
            print(f"  {target.language}: whatsNew は {whats_new_version} 向けなので {version_string} には書き込みません")

    available = client.localization_entries(version["id"])

    # 名前・サブタイトルはアプリ情報に書く。バージョンと同じく、次のバージョンを準備している間だけ編集できる
    app_info: dict | None = None
    info_available: dict[str, dict] = {}
    if info_entries:
        app_info = client.find_app_info(app["id"])
        if app_info is None:
            raise SystemExit(
                "名前・サブタイトルを編集できるアプリ情報がありません。"
                "App Store Connect で次のバージョンを作ってから実行してください。"
            )
        info_available = client.app_info_localization_entries(app_info["id"])

    # スクリーンショットのときと同じく、書き込む前に全言語ぶんの前提を確かめる
    plan: list[tuple[Language, dict[str, str], dict | None]] = []
    skipped: list[str] = []
    missing_locales: list[str] = []
    for target, attributes in entries:
        localization = available.get(target.store_locale)
        # 名前・サブタイトルを書く言語は、アプリ情報にもその言語が要る
        info_missing = target.language in info_entries and target.store_locale not in info_available
        if localization is None or info_missing:
            where = f"{version_string}" if localization is None else "アプリ情報"
            if args.missing_locales == "create":
                plan.append((target, attributes, localization))
            elif args.missing_locales == "skip":
                print(f"  飛ばす — {target.language}: {target.store_locale} が {where} にありません")
                skipped.append(target.language)
            else:
                missing_locales.append(f"{target.language} → {target.store_locale}（{where}）")
            continue
        plan.append((target, attributes, localization))

    if missing_locales:
        raise SystemExit(
            f"App Store Connect に無い言語: {', '.join(missing_locales)}\n"
            "App Store Connect でこれらの言語を追加してから実行するか、"
            "--missing-locales create（追加してから反映）か "
            "--missing-locales skip（飛ばす）を付けてください。"
        )

    from app_store_connect import ApiError

    # 名前・サブタイトル（アプリ情報）を先に書く。アプリ情報にその言語が無いままバージョンの言語を作ると、
    # App Store Connect がアプリ情報の言語を今の名前（主言語の名前）で作ろうとし、その名前がその言語で
    # ほかのアプリに使われていると、言語そのものを足せずに 409（DUPLICATE_NAME）で弾かれる（#538）
    failures, info_failed = write_app_info(client, args, app, app_info, info_available, info_entries, plan)

    if not args.dry_run:
        # アプリ情報の言語を作ると、App Store Connect がバージョンの言語も（中身が空のまま）作る。
        # 作り直すと 409（locale already exists）になるので、読み直して更新に回す（#540）
        available = client.localization_entries(version["id"])
        plan = [(target, attributes, localization or available.get(target.store_locale))
                for target, attributes, localization in plan]

    for target, attributes, localization in plan:
        label = f"{target.language} → {target.store_locale}"
        if localization is None:
            if target.language in info_failed:
                # 今の名前で作られて同じ 409 になるので、バージョンの言語も作らない
                print(f"  飛ばす — {label}: アプリ情報の言語を作れなかったので、バージョンの言語も作りません")
                continue
            try:
                client.create_localization(version["id"], target.store_locale, attributes)
            except ApiError as error:
                hint = "（今の名前がその言語でほかのアプリに使われている可能性があります）" if error.status == 409 else ""
                print(f"  {label}: 言語を追加できませんでした{hint}: {error}")
                failures.append(f"{label}（バージョンの言語）{hint}")
                continue
            print(f"  {label}: {'言語を追加して書き込む予定' if args.dry_run else '言語を追加して書き込み'}")
            for line in describe_changes({}, attributes):
                print(line)
            continue

        changes = describe_changes(localization["attributes"], attributes)
        if not changes:
            print(f"  {label}: 変更なし")
            continue
        print(f"  {label}: {'書き込む予定' if args.dry_run else '書き込み'}")
        for line in changes:
            print(line)
        if not args.dry_run:
            try:
                client.patch(
                    f"/v1/appStoreVersionLocalizations/{localization['id']}",
                    {
                        "data": {
                            "type": "appStoreVersionLocalizations",
                            "id": localization["id"],
                            "attributes": attributes,
                        }
                    },
                )
            except ApiError as error:
                # 1 言語の失敗で止めずに残りを書く（#542）
                print(f"    失敗: {error}")
                failures.append(label)

    if review_notes is not None:
        failures.extend(write_review_notes(client, args, version, review_notes))

    print(f"完了: {len(plan)} 言語")
    if skipped:
        print(f"飛ばした言語: {', '.join(skipped)}")
    if failures:
        print("書き込めなかったもの:")
        for line in failures:
            print(f"  - {line}")
        return 1
    return 0


def write_app_info(client, args: argparse.Namespace, app: dict, app_info: dict | None,
                   info_available: dict[str, dict], info_entries: dict[str, dict[str, str]],
                   plan: list[tuple[Language, dict[str, str], dict | None]]) -> tuple[list[str], set[str]]:
    """名前・サブタイトルをアプリ情報（`appInfoLocalizations`）に書く。
    書き込めなかった言語と理由・アプリ情報の言語を作れなかった言語（`Language.language`）を返す。

    バージョンの言語より先に呼ぶ。言語を足すときは、新しい名前でアプリ情報の言語を作ってから
    バージョンの言語を作る（逆の順だと、今の名前がその言語でほかのアプリに使われているときに 409 で弾かれる。#538）。
    足した言語のプライバシーポリシーの URL などは、主言語の値を写す（空のままだと審査に出せない）。
    名前は App Store 全体で一意なので、ほかのアプリが使っていると 409 で弾かれる。1 言語の失敗で止めずに残りを書く。
    """
    if app_info is None:
        return [], set()
    from app_store_connect import ApiError

    primary_locale = app["attributes"].get("primaryLocale") or ""
    primary = info_available.get(primary_locale, {}).get("attributes", {})

    failures: list[str] = []
    create_failed: set[str] = set()
    for target, _, _ in plan:
        info = info_entries.get(target.language)
        if not info:
            continue
        label = f"{target.language} → {target.store_locale}（名前・サブタイトル）"
        existing = info_available.get(target.store_locale)
        current = existing["attributes"] if existing else {}
        values = dict(info)
        for field in INFO_COPIED_FROM_PRIMARY:
            if not current.get(field) and primary.get(field):
                values[field] = primary[field]

        changes = describe_changes(current, values)
        if existing is not None and not changes:
            print(f"  {label}: 変更なし")
            continue
        if existing is None:
            print(f"  {label}: {'言語を追加して書き込む予定' if args.dry_run else '言語を追加して書き込み'}")
        else:
            print(f"  {label}: {'書き込む予定' if args.dry_run else '書き込み'}")
        for line in changes:
            print(line)
        if args.dry_run:
            continue
        try:
            if existing is None:
                client.create_app_info_localization(app_info["id"], target.store_locale, values)
            else:
                client.patch(
                    f"/v1/appInfoLocalizations/{existing['id']}",
                    {"data": {"type": "appInfoLocalizations", "id": existing["id"], "attributes": values}},
                )
        except ApiError as error:
            hint = "（名前がほかのアプリで使われている可能性があります）" if error.status == 409 else ""
            print(f"    失敗{hint}: {error}")
            failures.append(f"{label}{hint}")
            if existing is None:
                create_failed.add(target.language)
    return failures, create_failed


def write_review_notes(client, args: argparse.Namespace, version: dict, notes: str) -> list[str]:
    """審査メモを、反映先のバージョンの App Review に関する情報（`appStoreReviewDetails`）に書く。
    書き込めなかったものを返す。

    App Review に関する情報がまだ無いバージョンでは作らない。連絡先が空のまま作ると、
    App Store Connect の画面で連絡先を入れ直すまで審査に出せないため。
    """
    from app_store_connect import ApiError

    label = "審査メモ"
    detail = client.review_detail(version["id"])
    if detail is None:
        print(f"  {label}: このバージョンには App Review に関する情報がまだありません。"
              "App Store Connect で連絡先を入れて保存してから実行してください")
        return [f"{label}（App Review に関する情報がありません）"]

    changes = describe_changes(detail.get("attributes") or {}, {"notes": notes})
    if not changes:
        print(f"  {label}: 変更なし")
        return []
    print(f"  {label}: {'書き込む予定' if args.dry_run else '書き込み'}")
    for line in changes:
        print(line)
    if args.dry_run:
        return []
    try:
        client.patch(
            f"/v1/appStoreReviewDetails/{detail['id']}",
            {"data": {"type": "appStoreReviewDetails", "id": detail["id"], "attributes": {"notes": notes}}},
        )
    except ApiError as error:
        print(f"    失敗: {error}")
        return [label]
    return []


if __name__ == "__main__":
    sys.exit(main())
