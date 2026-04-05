FROM debian:stable-slim AS build

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git /flutter --branch stable --single-branch
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --enable-web
RUN flutter precache --web

WORKDIR /app
COPY . .

RUN flutter pub get
RUN flutter build web --release --dart-define=API_BASE_URL=http://16.171.52.29:5000/api/v1

FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]