FROM --platform=linux/amd64 node:18

RUN apt-get update && \
    apt-get -y install \
        ca-certificates \
        curl \
        fonts-freefont-ttf \
        fonts-ipafont-gothic \
        fonts-kacst \
        fonts-liberation \
        fonts-noto-color-emoji \
        fonts-thai-tlwg \
        fonts-wqy-zenhei \
        gconf-service \
        libasound2 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgcc1 \
        libgconf-2-4 \
        libgdk-pixbuf2.0-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        lsb-release \
        wget \
        xdg-utils \
        xvfb && \
    rm -rf /var/lib/apt/lists/*

COPY src/*.js /
COPY package.json /
COPY package-lock.json /
COPY template/ template/
COPY styles/ styles/

RUN npm ci
RUN fc-cache -fv && \
    chmod +x /github_interface.js && \
    mkdir /pdf && \
    chmod 777 /pdf && \
    ln -s /github_interface.js /usr/local/bin/markdown-to-pdf

CMD [ "markdown-to-pdf" ]
