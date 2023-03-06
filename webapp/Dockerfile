FROM node:19-alpine

# Set the current working directory
RUN mkdir /app
WORKDIR /app

# Prepare the folder storing the wallet information
RUN mkdir /app/wallet

# Build the node project
COPY package*.json .
RUN npm install
COPY . .

# Run the web application
EXPOSE 3000
CMD ["node", "index.js"]