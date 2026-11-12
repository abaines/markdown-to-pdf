FROM --platform=linux/amd64 node:26.12.1-trixie@sha256:97fa0f1b59035c6072721a88d55be1371c7cb1cc942b521e1cc5c72ec87655f4

RUN apt-get update && \
    apt-get -y install \
        ca-certificates \
        chromium \
        fonts-freefont-ttf \
        fonts-ipafont-gothic \
        fonts-liberation \
        fonts-noto-color-emoji \
        fonts-thai-tlwg \
        fonts-wqy-zenhei \
        libxss1 \
        lsb-release \
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
