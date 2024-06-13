FROM ollama/ollama:0.1.38

WORKDIR /app

COPY ./dist/replicant-worker .
COPY ./sh/start.sh .

RUN mkdir -p /app/.models
RUN chmod +x /app/start.sh

ENTRYPOINT [ "/app/start.sh" ]
