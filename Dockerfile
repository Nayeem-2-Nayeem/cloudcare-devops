FROM node:18
WORKDIR /usr/src/app

# Copy package files first
COPY app/package*.json ./
RUN npm install

# Copy app source code
COPY app/ ./

EXPOSE 3000
CMD ["node", "app.js"]


