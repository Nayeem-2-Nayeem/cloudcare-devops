FROM node:18
WORKDIR /usr/src/app

# Copy only package files first for caching npm install
COPY app/package*.json ./
RUN npm install

# Copy only the app source code
COPY app/ ./

EXPOSE 3000
CMD ["node", "app.js"]

