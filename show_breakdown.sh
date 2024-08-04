#!/bin/bash

# 引数の解析
SAVE_FILE=false
OUTPUT_BASE=""
FORMAT=""

while getopts ":o:f:" opt; do
  case ${opt} in
    o )
      SAVE_FILE=true
      OUTPUT_BASE=$OPTARG
      ;;
    f )
      if [[ "$OPTARG" == "csv" || "$OPTARG" == "tsv" ]]; then
        FORMAT=$OPTARG
      else
        echo "Invalid format: $OPTARG. Only 'csv' or 'tsv' are allowed."
        exit 1
      fi
      ;;
    \? )
      echo "Invalid option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: -$OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ $# -gt 1 ]; then
    echo "Error!"
    echo "The number of arguments is wrong."
    exit 1
fi

# 初期リストの取得
if [ $# -eq 0 ]; then
    if [ -p /dev/stdin ]; then
        CURRENT_LIST="$(cat)"
    else
        echo "Error!"
        echo "There is no argument."
        echo "Usage: showbd [-o output] [-f format] [a one-column list]"
        exit 1
    fi
else
    CURRENT_LIST="$(cat "$1")"
fi

# オプションが指定されている場合のチェック
if $SAVE_FILE && [ -z "$FORMAT" ]; then
    echo "Error! -o option requires -f option to specify the format (csv or tsv)."
    exit 1
fi

if ! $SAVE_FILE && [ ! -z "$FORMAT" ]; then
    echo "Error! -f option requires -o option to specify the output file base name."
    exit 1
fi

# リストの総数をカウント
TOTAL=$(echo "$CURRENT_LIST" | wc -l)

# ブレークダウンの計算
BREAKDOWN=$(
    while [ -n "$(echo "$CURRENT_LIST")" ]; do
        key=$(echo "$CURRENT_LIST" | head -n 1)
        val=$(echo "$CURRENT_LIST" | grep "^$key$" | wc -l)
        printf "%3s\t" $val
        echo $key
        CURRENT_LIST=$(echo "$CURRENT_LIST" | sed -e "/^$key$/d")
    done |
    sort -rn -k1
)

# 結果の表示
CHKSUM=$(echo "$BREAKDOWN" | awk '{a+=$1} END{print a;}')
if [ $TOTAL != $CHKSUM ]; then
    echo "Error. The totals for all items in the breakdown do not match the original data."
    printf "The original data: %3s\n" $TOTAL
    printf "The totals for all items in the breakdown: %3s\n\n" $CHKSUM
    exit 1
fi
printf "%3s\t" $TOTAL
echo "Total ("$(echo "$BREAKDOWN" | wc -l) "categories)"
echo "=============================="
echo "$BREAKDOWN"
echo "=============================="

# オプションが指定されている場合はファイルに保存
if $SAVE_FILE; then
    OUTPUT_FILE="${OUTPUT_BASE}.${FORMAT}"
    if [ "$FORMAT" == "csv" ]; then
        echo -e "Count,Category\n$BREAKDOWN" | tr '\t' ',' > "$OUTPUT_FILE"
    elif [ "$FORMAT" == "tsv" ]; then
        echo -e "Count\tCategory\n$BREAKDOWN" > "$OUTPUT_FILE"
    fi
    echo "Results saved to $OUTPUT_FILE in $FORMAT format"
fi
