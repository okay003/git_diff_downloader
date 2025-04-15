#!/bin/bash

# このファイルの説明
# - このスクリプトは、Gitリポジトリ間の差分を比較し、差分があるファイルだけを階層構造を維持したままダウンロードします。
#
# 主な機能
# - 指定された2つのGitリポジトリの差分を取得
# - 差分に基づいて変更されたファイルをリストアップ
# - 必要に応じて変更されたファイルをダウンロード
#
# 使用方法
# - sh git_diff_downloader.sh <gitディレクトリまでのパス> <変更前コミットID> <変更後コミットID>
# - 例 : sh .\git_diff_downloader.sh path/to/repo 61a474 98fc95 

# ----------------------------------------------------------------------------------------------------

# 名前の定義
G_DIR_DIFF_BASE="diff"
G_FILE_NAME_DIFF="diff.txt"

# ----------------------------------------------------------------------------------------------------

# 引数の確認
if [ "$#" -ne 3 ]; then
    echo "使い方 : $0 <gitディレクトリまでのパス> <変更前コミットID> <変更後コミットID>"
    exit 1
fi

# 引数の取得
G_PATH_GIT=$1
G_COMMIT_BEFORE=$2
G_COMMIT_AFTER=$3

echo "--------------------------------------------------"
echo "Gitディレクトリまでのパス : $G_PATH_GIT"
echo "変更前コミットID          : $G_COMMIT_BEFORE"
echo "変更後コミットID          : $G_COMMIT_AFTER"

# gitディレクトリの確認
if [ ! -d "$G_PATH_GIT/.git" ]; then
    echo "エラー : $G_PATH_GIT はgitリポジトリではありません"
    exit 1
fi

# ----------------------------------------------------------------------------------------------------

# ディレクトリ名の材料
G_NAME_REPOSITORY=$(basename "$G_PATH_GIT")
G_COMMIT_BEFORE_SHORT=$(echo "$G_COMMIT_BEFORE" | cut -c 1-7)
G_COMMIT_AFTER_SHORT=$(echo "$G_COMMIT_AFTER" | cut -c 1-7)

# 差分ファイル格納先
G_DIR_DIFF="$G_DIR_DIFF_BASE-$G_NAME_REPOSITORY-$G_COMMIT_BEFORE_SHORT-$G_COMMIT_AFTER_SHORT"
G_PATH_FILE_DIFF="$G_DIR_DIFF/$G_FILE_NAME_DIFF"

# ----------------------------------------------------------------------------------------------------

# コミット間の差分を抽出し保存する関数
function diff_finder(){
    # 出力ディレクトリの作成
    mkdir -p "$G_DIR_DIFF"
    echo "--------------------------------------------------"
    echo "ディレクトリ作成          : $G_DIR_DIFF"

    # 差分を取得してFILE_DIFFに保存
    git -C "$G_PATH_GIT" diff --name-only "$G_COMMIT_BEFORE" "$G_COMMIT_AFTER" > "$G_PATH_FILE_DIFF"
    echo "差分ファイル一覧作成      : $G_PATH_FILE_DIFF"
}

# ----------------------------------------------------------------------------------------------------

# 差分ファイル一覧を読み込み、ファイルをダウンロードする関数
function file_downloader(){
    # 引数の確認
    if [ "$#" -ne 2 ]; then
        echo "使い方 : $0 <output_directory> <commit_id>"
        exit 1
    fi

    # 引数の取得
    DIR_OUTPUT=$G_DIR_DIFF/$1
    COMMIT_ID=$2

    # FILE_DIFFの存在確認
    if [ ! -f "$G_PATH_FILE_DIFF" ]; then
        echo "エラー : $G_PATH_FILE_DIFF は存在しません"
        exit 1
    fi

    # 出力ディレクトリの作成
    mkdir -p "$DIR_OUTPUT"
    echo "--------------------------------------------------"
    echo "保存先ディレクトリ作成    : $DIR_OUTPUT"
    
    # FILE_DIFFを読み込み、ファイルをダウンロード
    while IFS= read -r PATH_FILE; do
        # ファイルが存在するか確認
        if git -C "$G_PATH_GIT" cat-file -e "$COMMIT_ID:$PATH_FILE" 2>/dev/null; then
            # ファイルのディレクトリ構造を維持してコピー
            DIR_DEST="$DIR_OUTPUT/$(dirname "$PATH_FILE")"
            mkdir -p "$DIR_DEST"
            git -C "$G_PATH_GIT" show "$COMMIT_ID:$PATH_FILE" > "$DIR_OUTPUT/$PATH_FILE"
            echo "ダウンロード完了          : $G_NAME_REPOSITORY/$PATH_FILE"
        else
            echo "スキップ                  : $G_NAME_REPOSITORY/$PATH_FILE ($COMMIT_ID に存在しないファイル)"
        fi
    done < $G_PATH_FILE_DIFF
}

# ----------------------------------------------------------------------------------------------------

# 実行
diff_finder
file_downloader 00_before $G_COMMIT_BEFORE
file_downloader 01_after $G_COMMIT_AFTER

# ----------------------------------------------------------------------------------------------------

# 終了メッセージ
echo "--------------------------------------------------"
echo "完了"
