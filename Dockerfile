FROM ruby:3.0-slim

LABEL maintainer="あなたの名前 <your.email@example.com>"
LABEL description="Narou.rb - 小説家になろうダウンローダー＆縦書き整形＆管理アプリ"
ENV DOCKER_ENV=true

# システム依存関係のインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    build-essential \
    wget \
    gnupg \
    software-properties-common \
    vim \
    # ヘッドレスブラウザとその依存関係
    chromium \
    chromium-driver \
    xvfb \
    && rm -rf /var/lib/apt/lists/*

# OpenJDK 21をインストール (Java 11から21に変更)
RUN apt-get update && \
    mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y temurin-21-jre \
    && rm -rf /var/lib/apt/lists/*


# Javaバージョンを確認
RUN java -version

# 作業ディレクトリの設定
WORKDIR /app

# ソースコードをコピー
COPY . /app/

# bundlerをインストール
RUN gem install bundler

# tiltを特定のバージョンでインストール
RUN gem install tilt -v '2.0.10'

# gemspecからgemパッケージをビルドしてインストール
RUN cd /app && \
    gem build *.gemspec && \
    gem install *.gem

# AozoraEpub3のセットアップ - 特定バージョンのリリースファイルを使用
RUN mkdir -p /app/aozoraepub3 && \
    curl -L https://github.com/kyukyunyorituryo/AozoraEpub3/releases/download/v1.1.1b30Q/AozoraEpub3-1.1.1b30Q.zip -o /tmp/aozoraepub3.zip && \
    unzip /tmp/aozoraepub3.zip -d /tmp/aozoraepub3_temp && \
    cp -R /tmp/aozoraepub3_temp/* /app/aozoraepub3/ && \
    rm -rf /tmp/aozoraepub3.zip /tmp/aozoraepub3_temp && \
    chmod +x /app/aozoraepub3/*.sh || true

# 小説データ用のボリュームを作成
VOLUME ["/app/novels"]

# Narou.rbの初期化
RUN narou init -p /app/aozoraepub3
RUN narou setting server-ws-add-accepted-domains="*"

# Web UIポート
EXPOSE 33000

# Web UIサーバーを起動するコマンド
CMD ["narou", "web", "-n", "-p", "33000", "--backtrace"]