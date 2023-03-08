FROM node:19

# Set the current working directory
RUN mkdir /app
WORKDIR /app

# Prepare the folder storing the wallet information
RUN mkdir /app/wallet

# Build the node project
COPY package*.json .
RUN npm install
COPY . .

# Fix potential windows line terminator error
RUN sed -i 's/\r//g' scripts/*.sh

# Run the web application
EXPOSE 3000
CMD ["node", "index.js"]