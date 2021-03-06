gbc
===

ゲームブック作成用のコンバータです。
複数のフォーマットに対応可能です(単一テキストファイルのみ出力できます)

# 開発環境

Ubuntu Linux 12.04 LTS @ VirtualBox
ruby 2.0.0-p195

# シナリオの基本の仕様

本ソフトでは、入力ファイルの内容を「シナリオ」と呼びます。
一つのシナリオは、一つのテキストファイルで構成します。
シナリオは、UTF-8で記述してください。

シナリオは、以下の2つの部分で構成されています。

* 前設定
* ラベル
* 本文

## 前設定

事前に定義しておく内容です。

    FIRST=N

最初のパラグラフ番号をNに変更します。省略時は1です。

## ラベル

パラグラフ番号に置き換えられる名前です。行頭で、以下のように記述します。

    ●[ラベル名]

変換時にラベル名がシャッフルされたパラグラフ番号に置き換えられます。

    ●●[パラグラフ番号]

記述した番号をパラグラフ番号とします(このパラグラフ番号を「固定ラベル」と呼びます)。
ただし、最初のパラグラフ番号以下や最後のパラグラフ番号より大きなパラグラフ番号を指定するとエラーになります。

    ●●FIRST

最初のパラグラフ番号に置き換えられます。
必ず記述する必要があります。

    ●●LAST

最後のパラグラフ番号に置き換えられます。省略可能です。
ただし、上記ラベルと同時に最後のパラグラフ番号を固定ラベルとして記述するとエラーになります。

## 本文

パラグラフ本文です。基本的に、度の文章でもかけます。
ただし、本文が空だとエラーになります。

    ##[ラベル]##

本文中に書くと、指定したラベルに対応したパラグラフ番号に置き換えられます。
定義されていないラベルと指定するとエラーになります。

残りは、各自で定義可能です。

# 拡張について

本スクリプトは、以下のクラスを各自定義することで、出力の拡張ができます。

## Formatter

パラグラフを整形する時に渡すオブジェクトです。
Converter.newの引数として渡します。

Formatterには、以下のメソッドを定義する必要があります。

* pre\_process

解析前のシナリオを整形するときなどに使います。
シナリオ(文字列の配列)が引数となり、整形したシナリオ(文字列の配列)を返します。

* convert

本文を行単位で変換します。
Paragraphsオブジェクト、本文の1行が渡ってきます。
変換した文字列を返します。

* post\_process

解析された本文を整形などするときに使います。
Paragraphsオブジェクト、ラベル、パラグラフ番号、本文が渡ってきます。
文字列の配列を返します。

* output

パラグラフを出力します。
Paragraphsオブジェクト、パラグラフ番号、本文が渡ってきます。
値を返す必要はありません。

* shuffle?

パラグラフ番号をシャッフルするかをtrue/falseで返します。
falseを返すようにすると、記述した順番にパラグラフ番号が降られます。

* out\_type

出力形式を書きます。
現在は使用していません。

## Processors

パラグラフ解析時に渡すオブジェクトの配列です。
Converter.newの引数として渡します。

Processorsには、以下のメソッドを定義する必要があります。

* regext

Processorに処理を渡すためのトリガーとなる正規表現を返します。
マッチしたときのみ、processメソッドが呼ばれます。

* process

正規表現にマッチしたときの処理を記述します。
Paragraphsオブジェクト、マッチした行、MatchDataオブジェクトが引数として渡ってきます。
値を返す必要はありません。
ここで入力された行はパラグラフの本文には含まれません。

