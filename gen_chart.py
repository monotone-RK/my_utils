import pandas as pd
import matplotlib.pyplot as plt
import argparse
import os

def read_file(file):
    # ファイル拡張子を取得
    ext = os.path.splitext(file)[1]
    if ext == '.csv':
        return pd.read_csv(file)
    elif ext == '.tsv':
        return pd.read_csv(file, sep='\t')
    else:
        raise ValueError(f"Unsupported file type: {ext}")

def plot_data(files, x_column, y_column, output_file, plot_type):
    if plot_type != 'pie':
        plt.figure(figsize=(18, 10))

    colors = plt.get_cmap('tab20').colors  # カラーマップから色を取得

    for i, file in enumerate(files):
        # データファイルを読み込む
        df = read_file(file)

        # 横軸と縦軸のラベルを取得
        x_data = df[x_column]
        y_data = df[y_column]

        # ファイル名から拡張子を除いて取得
        legend_name = os.path.splitext(os.path.basename(file))[0]

        # 色を決定
        color = colors[i % len(colors)]

        # データをプロット
        if plot_type == 'line':
            plt.plot(x_data, y_data, marker='o', linestyle='-', label=legend_name, color=color)
        elif plot_type == 'bar':
            plt.bar(x_data, y_data, label=legend_name, color=color)
        elif plot_type == 'scatter':
            plt.scatter(x_data, y_data, label=legend_name, color=color)
        elif plot_type == 'pie':
            plt.figure(figsize=(10, 10))
            plt.pie(y_data, labels=x_data, autopct='%1.1f%%', startangle=90, counterclock=False, colors=[colors[j % len(colors)] for j in range(len(y_data))])
            plt.title(f'{legend_name} Pie Chart')
            plt.savefig(output_file, format='svg', bbox_inches='tight')
            plt.show()
            plt.clf()
        else:
            raise ValueError(f"Unsupported plot type: {plot_type}")

    if plot_type != 'pie':
        # フォントサイズを設定
        plt.xlabel(x_column, fontsize=20)
        plt.ylabel(y_column, fontsize=20)
        plt.xticks(fontsize=20, ha='center')
        plt.yticks(fontsize=20)

        # 凡例を表示（グラフのボックスの外、中央の上側、横並び）
        plt.legend(loc='upper center', bbox_to_anchor=(0.5, 1.1), fontsize=20, ncol=len(files))

        # レイアウトを調整
        plt.tight_layout(rect=[0, 0, 1, 0.95])

        # SVGファイルとして保存
        plt.savefig(output_file, format='svg', bbox_inches='tight')

        # グラフを表示
        plt.show()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Plot data from files.')
    parser.add_argument('-i', '--input', nargs='+', required=True, help='Input data file(s)')
    parser.add_argument('-x', '--xcolumn', required=True, help='Column name for x-axis')
    parser.add_argument('-y', '--ycolumn', required=True, help='Column name for y-axis')
    parser.add_argument('-o', '--output', required=True, help='Output SVG file')
    parser.add_argument('-t', '--type', required=True, choices=['line', 'bar', 'scatter', 'pie'], help='Type of plot: line, bar, scatter, pie')
    args = parser.parse_args()

    plot_data(args.input, args.xcolumn, args.ycolumn, args.output, args.type)
