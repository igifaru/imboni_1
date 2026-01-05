FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist/apps/pftcv-service ./
EXPOSE 3008
CMD ["node", "src/main.js"]
