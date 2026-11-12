FROM --platform=linux/amd64 node:26.12.1-trixie@sha256:97fa0f1b59035c6072721a88d55be1371c7cb1cc942b521e1cc5c72ec87655f4

RUN apt-get update && \
    apt-get -y install \
        ca-certificates \
        chromium \
        curl \
        fonts-freefont-ttf \
        fonts-ipafont-gothic \
        fonts-liberation \
        fonts-noto-color-emoji \
        fonts-thai-tlwg \
        fonts-wqy-zenhei \
        libasound2 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgcc1 \
        libgdk-pixbuf-2.0-0 \
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

# Render with Debian's open source Chromium, not a browser downloaded by Puppeteer.
ENV PUPPETEER_SKIP_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

COPY src/*.js /
COPY .npmrc /
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
