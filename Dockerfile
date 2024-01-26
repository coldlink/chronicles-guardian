FROM node:20-alpine as builder
WORKDIR /usr/src/app
COPY package.json .
COPY package-lock.json .
RUN npm ci

FROM ghcr.io/static-web-server/static-web-server:2-alpine as run
ARG SERVICE_ACCOUNT
ENV SERVICE_ACCOUNT $SERVICE_ACCOUNT
ARG DRIVE_FOLDER_ID
ENV DRIVE_FOLDER_ID $DRIVE_FOLDER_ID
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/ /usr/src/app/
COPY . .
RUN echo "installing dependencies..."
RUN apk add --update alpine-sdk bash curl nodejs npm go
RUN echo "installing dependencies... done"
RUN echo "updating npm..."
RUN npm install -g npm@latest
RUN echo "updating npm... done"
RUN echo "install drive-google..."
RUN go install github.com/odeke-em/drive/cmd/drive@latest
RUN echo "install drive-google... done"
RUN echo "configure drive-google..."
RUN echo $SERVICE_ACCOUNT > /usr/src/app/service-account.json
RUN ~/go/bin/drive init --service-account-file /usr/src/app/service-account.json ~/gdrive
RUN cd ~/gdrive && ~/go/bin/drive pull -hidden -id $DRIVE_FOLDER_ID
RUN echo "configure drive-google... done"
RUN echo "setting up cron job..."
RUN echo "*/30 * * * * echo \"checking and pulling files...\" && cd ~/gdrive && ~/go/bin/drive pull -hidden -id $DRIVE_FOLDER_ID && echo \"checking and pulling files... done\" && echo \"rebuilding project...\" && cd /usr/src/app && npx quartz build && cp -TR public server && echo \"rebuilding project... done\"" > /etc/crontabs/root
RUN echo "setting up cron job... done"
RUN echo "setting up symbolic link..."
RUN ln -s ~/gdrive/The\ Fey\ Isles/Chronicles\ of\ the\ Guardians /usr/src/app/content
RUN echo "setting up symbolic link... done"
RUN echo "running initial build..."
RUN npx quartz build
RUN cp -TR public server
RUN echo "running initial build... done"
RUN chmod +x /usr/src/app/docker-start.sh
EXPOSE 8081
CMD ["/usr/src/app/docker-start.sh"]
