FROM --platform=linux/amd64 node:26.13.0-trixie@sha256:438603bbb5cda404b9416f0b5c8026f61501ab911760d861ec28c36b5d675725

RUN apt-get update && \
    apt-get -y install \
        ca-certificates \
        chromium \
        fonts-freefont-ttf \
        fonts-ipafont-gothic \
        fonts-liberation \
        fonts-noto-color-emoji \
        fonts-thai-tlwg \
        fonts-wqy-zenhei && \
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
