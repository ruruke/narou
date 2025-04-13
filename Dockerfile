FROM ruby:3.0-slim

LABEL maintainer="あなたの名前 <your.email@example.com>"
LABEL description="Narou.rb - 小説家になろうダウンローダー＆縦書き整形＆管理アプリ"

# システム依存関係のインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    build-essential \
    wget \
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# OpenJDK 11をインストール
RUN apt-get update && apt-get install -y \
    openjdk-11-jre-headless \
    && rm -rf /var/lib/apt/lists/*


# Javaバージョンを確認
RUN java -version

# 作業ディレクトリの設定
WORKDIR /app

# Narou.rbと必要な依存関係のインストール
RUN gem install narou && \
    gem install erubis && \
    gem install tilt && \
    gem install sinatra-contrib && \
    gem install slim && \
    gem install sass


# AozoraEpub3のセットアップ - GitHubからクローン
RUN git clone --depth 1 https://github.com/kyukyunyorituryo/AozoraEpub3.git /app/aozoraepub3

# 小説データ用のボリュームを作成
VOLUME ["/app/novels"]

# Narou.rbの初期化
RUN narou init -p /app/aozoraepub3

# Web UIポート
EXPOSE 33000

# Web UIサーバーを起動するコマンド
CMD ["narou", "web", "-p", "33000"]