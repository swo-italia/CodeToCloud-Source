FROM node:alpine AS base
WORKDIR /usr/src/app
ENV MONGODB_CONNECTION=mongodb://mongo:27017/contentdb

FROM node:argon AS build
WORKDIR /usr/src/app

# Install app dependencies
COPY package.json /usr/src/app/
RUN npm install
#RUN npm audit fix

# Bundle app source
COPY . /usr/src/app

# Prepare container image
FROM base as final
WORKDIR /usr/src/app
COPY --from=build /usr/src/app .
CMD [ "npm", "start" ]