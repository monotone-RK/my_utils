#!/usr/bin/env bash
set -eu

########################################
# 引数チェック
########################################
if [ "$#" -lt 6 ] || [ "$#" -gt 8 ]; then
  cat >&2 <<EOF
Usage: $0 CSV_FILE START_INDEX END_INDEX OUTPUT_PDF NAME_COL AFFIL_COL [AMOUNT_COL] [DATE_COL]

  START_INDEX / END_INDEX : データ行 (ヘッダを除いた行) の 1 始まりの番号
  NAME_COL                : 名前カラム番号 (1 始まり)
  AFFIL_COL               : 所属カラム番号 (1 始まり)
  AMOUNT_COL              : 金額カラム番号 (省略可, 0 扱い)
  DATE_COL                : 日付カラム番号 (省略可, 0 扱い)

例:
  ./generate_receipts.sh list.csv 1 30 receipts.pdf 3 5 7 8
EOF
  exit 1
fi

CSV_FILE="$1"
START_INDEX="$2"
END_INDEX="$3"
OUTPUT_PDF="$4"
NAME_COL="$5"
AFFIL_COL="$6"
AMOUNT_COL="${7:-0}"  # 0 の場合は CSV から読まず DEFAULT_AMOUNT を使う
DATE_COL="${8:-0}"    # 0 の場合は日付を印字しない

########################################
# 設定（必要に応じて変更）
########################################
# 領収書共通情報
ISSUER_NAME="IPSJ ARC/HPC、IEICE CPSY合同研究会"
ISSUER_ADDR="懇親会担当　大西 隆之、小林 諒平、江川 隆輔、佐藤 雅之"

# 金額のデフォルト値（AMOUNT_COL=0 のときや空欄時に使用）
DEFAULT_AMOUNT=4500

# 但し書き部分
PURPOSE_TEXT="IPSJ ARC/HPC、IEICE CPSY合同研究会 懇親会代金"

########################################
# TeX コマンド確認
########################################
if ! command -v platex >/dev/null 2>&1; then
  echo "Error: platex が見つかりません (TeX 環境をインストールしてください)" >&2
  exit 1
fi

if ! command -v dvipdfmx >/dev/null 2>&1; then
  echo "Error: dvipdfmx が見つかりません (dvipdfmx が必要です)" >&2
  exit 1
fi

########################################
# 一時ディレクトリ
########################################
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
TEX_FILE="$TMPDIR/receipts.tex"

########################################
# LaTeX プリアンブル（A4 横向き）
########################################
cat > "$TEX_FILE" <<'EOF'
\documentclass[dvipdfmx,a4paper]{jsarticle}
\usepackage[paper=a4paper,landscape,top=20mm,bottom=20mm,left=25mm,right=25mm]{geometry}
\usepackage[dvipdfmx]{xcolor}
\usepackage{tikz}
\usetikzlibrary{decorations.pathmorphing}
\pgfmathsetseed{20241118} % reproducible grain for the digital stamp
\newcommand{\digiseal}[1][1.10]{%
  \tikz[baseline=-0.6ex,scale=#1,transform shape]{%
    \begin{scope}[rotate=-12]
      % faint ink bleed + grain (digital印影風)
      \shade[inner color=red!22, outer color=red!4, opacity=0.95] (0,0) circle[radius=8.3mm];
      \foreach \i in {1,...,110}{
        \pgfmathsetmacro{\x}{rnd*15-7.5}
        \pgfmathsetmacro{\y}{rnd*15-7.5}
        \fill[red!40, opacity=0.32] (\x mm,\y mm) circle[radius=0.12mm];
      }
      \draw[red!85, line width=1.1pt,
            decoration={random steps,segment length=2.0mm,amplitude=0.35mm},
            decorate] (0,0) circle[radius=8mm];
      \draw[red!70, line width=0.55pt, opacity=0.65] (0,0) circle[radius=7.15mm];
      \node[red!85, font=\bfseries\Large, opacity=0.95]  at (0,0) {済};
      \node[red!60, font=\bfseries\Large, opacity=0.32] at (0.32mm,-0.28mm) {済};
    \end{scope}
  }%
}
\pagestyle{empty}
\begin{document}
EOF

########################################
# CSV → TeX (1 人 1 ページ)
########################################
awk -F',' \
  -v s="$START_INDEX" \
  -v e="$END_INDEX" \
  -v name_col="$NAME_COL" \
  -v affil_col="$AFFIL_COL" \
  -v amount_col="$AMOUNT_COL" \
  -v date_col="$DATE_COL" \
  -v issuer_name="$ISSUER_NAME" \
  -v issuer_addr="$ISSUER_ADDR" \
  -v default_amount="$DEFAULT_AMOUNT" \
  -v purpose_text="$PURPOSE_TEXT" \
  -v out="$TEX_FILE" '
# --- LaTeX 用の簡易エスケープ ---
function tex_escape(str) {
    gsub(/\\/,"\\\\textbackslash ",str)
    gsub(/\&/,"\\&",str)
    gsub(/%/,"\\%",str)
    gsub(/\$/,"\\$",str)
    gsub(/#/,"\\#",str)
    gsub(/_/,"\\_",str)
    gsub(/\^/,"\\^{}",str)
    gsub(/~/,"\\~{}",str)
    return str
}

# 金額を 3 桁区切りにする ("4000" → "4,000")
function format_amount(num,   s, res) {
    s = num
    gsub(/^[ \t]+|[ \t]+$/, "", s)
    if (s == "") return ""
    res = ""
    while (length(s) > 3) {
        res = "," substr(s, length(s)-2, 3) res
        s = substr(s, 1, length(s)-3)
    }
    res = s res
    return res
}

BEGIN {
    data_row = 0    # ヘッダを除いた行番号
    first = 1       # 最初のページ判定
}

NR == 1 {
    # ヘッダ行はスキップ
    next
}

{
    data_row++

    # 範囲外なら何もしない
    if (data_row < s || data_row > e) {
        next
    }

    # ---------- 各フィールド取得 ----------
    name_raw = $(name_col)
    aff_raw  = $(affil_col)

    # 金額
    if (amount_col > 0) {
        raw_amount = $(amount_col)
        gsub(/,/, "", raw_amount)    # 既存のカンマは削除しておく
        if (raw_amount == "") {
            raw_amount = default_amount
        }
    } else {
        raw_amount = default_amount
    }
    amount_fmt = format_amount(raw_amount)

    # 日付
    if (date_col > 0) {
        date_raw = $(date_col)
    } else {
        date_raw = "2025年12月15日"
    }

    # TeX エスケープ
    name  = tex_escape(name_raw)
    aff   = tex_escape(aff_raw)
    amount = tex_escape(amount_fmt)
    date  = tex_escape(date_raw)
    ptext = tex_escape(purpose_text)
    iname = tex_escape(issuer_name)
    iaddr = tex_escape(issuer_addr)

    # 2ページ目以降の先頭で改ページ
    if (!first) {
        print "\\newpage" >> out
    }
    first = 0

    # ---------- ここから 1 ページ分 (A4 横レイアウト) ----------
    print "\\thispagestyle{empty}" >> out

    # 上部: 左に No., 右に日付
    if (date != "") {
        # No. と日付を 2 カラムで
        printf "\\noindent\\begin{minipage}[t]{0.5\\textwidth}{\\Large No.~%d}\\end{minipage}%%\n", data_row >> out
        printf "\\begin{minipage}[t]{0.5\\textwidth}\\begin{flushright}{\\Large %s}\\end{flushright}\\end{minipage}\\\\[8mm]\n", date >> out
    } else {
        printf "\\noindent {\\Large No.~%d}\\\\[8mm]\n", data_row >> out
    }

    # タイトル（中央）
    print "\\begin{center}{\\Huge \\bfseries 領収証}\\end{center}" >> out
    print "\\vspace*{10mm}" >> out

    # 所属（左寄せ）
    printf "\\begin{flushleft}{\\LARGE %s}\\end{flushleft}\n", aff >> out
    print "\\vspace*{8mm}" >> out

    # 氏名 様（中央）
    printf "\\begin{center}{\\LARGE %s\\ 様}\\end{center}\n", name >> out
    print "\\vspace*{8mm}" >> out

    # 金額（中央・下線付き）
    printf "\\begin{center}{\\Huge \\bfseries 金\\ \\underline{\\hspace{10mm}%s\\hspace{10mm}}\\ 円}\\end{center}\n", amount >> out
    print "\\vspace*{2mm}" >> out
    print "\\begin{center}{(消費税込み)}\\end{center}" >> out

    # 但し書き
    printf "\\vspace*{8mm}\n" >> out
    printf "\\noindent {\\Large 但し、%sとして上記正に領収いたしました。}\\\\[3mm]\n", ptext >> out

    # 下部 右側に発行者情報
    print "\\vspace*{6mm}" >> out
    print "\\begin{flushright}" >> out
    printf "{\\Large %s}\\\\\n", iname >> out
    printf "{\\Large %s\\hspace{6mm}\\digiseal}\\\\\n", iaddr >> out
    print "\\end{flushright}" >> out
}
' "$CSV_FILE"

########################################
# LaTeX 終端
########################################
cat >> "$TEX_FILE" <<'EOF'
\end{document}
EOF

########################################
# PDF 生成
########################################
(
  cd "$TMPDIR"
  platex -interaction=nonstopmode receipts.tex >/dev/null 2>&1
  dvipdfmx receipts.dvi >/dev/null 2>&1
)

cp "$TMPDIR/receipts.pdf" "$OUTPUT_PDF"
echo "Generated PDF: $OUTPUT_PDF"
