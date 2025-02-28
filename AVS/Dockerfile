FROM node:20-alpine

RUN npm install -g npm@latest

WORKDIR /app

RUN npm i -g @othentic/othentic-cli-sepolia

ENTRYPOINT [ "othentic-cli" ]
