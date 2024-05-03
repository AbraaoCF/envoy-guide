# Guia Envoy
Nesse guia nós contruíremos nossa `envoymesh` com três services envoy rodando, uma como front-envoy na borda da aplicação (como esse guia em blog na aws, [Setting Up an Envoy Front Proxy on Amazon ECS](https://aws.amazon.com/pt/blogs/compute/setting-up-an-envoy-front-proxy-on-amazon-ecs/)) e os outros dois como sidecar de um serviço flask rodando. Ainda colocaremos um serviço externo para authorizar requests.

Veja o esquema abaixo: 
![Imagem do esquema](./extra/scheme.png)

## Instalação


Um pré-requisito para esse guia é rodar Docker em sua máquina, veja [Install Docker Engine](https://docs.docker.com/engine/install/).

### Clonar o Repositório

Para começar, clone o repositório do projeto para sua máquina local:

```bash
git clone <URL_DO_REPOSITORIO>
``` 
### Executar Docker Compose

Após clonar o repositório, navegue até o diretório do projeto e execute o comando Docker Compose para construir e iniciar os contêineres:

```bash
cd envoy-guide
docker-compose up --build -d
``` 

## Passo-a-passo

### Rodar o GET através do envoy
Agora que o projeto está configurado e em execução, teste as nossas <b>rotas GET</b>.

O objetivo testar o sistema com front-proxy e alcancar o mesmo IP executando a chamada HTTP pela porta 8080 e HTTPS pela porta 8443 para um mesmo serviço (verifique o campo de saída `resolved`):

#### Get HTTP:
```bash
curl -v localhost:8080/service/1
```

```
*  Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /service/1 HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.1.2
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-type: text/plain; charset=utf-8
< content-length: 83
< date: Thu, 02 May 2024 18:11:02 GMT
< server: envoy
< x-envoy-upstream-service-time: 99
< 
Hello Anonymous OPA from behind Envoy 1!
hostname 6c0898c665f1
resolved 172.23.0.3
* Connection #0 to host localhost left intact
```
#### Get HTTPS:
```bash
curl -v -k https://localhost:8443/service/1
```

```
*   Trying 127.0.0.1:8443...
* Connected to localhost (127.0.0.1) port 8443 (#0)
* ALPN: offers h2,http/1.1
* (304) (OUT), TLS handshake, Client hello (1):
* (304) (IN), TLS handshake, Server hello (2):
* (304) (IN), TLS handshake, Unknown (8):
* (304) (IN), TLS handshake, Certificate (11):
* (304) (IN), TLS handshake, CERT verify (15):
* (304) (IN), TLS handshake, Finished (20):
* (304) (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / AEAD-AES256-GCM-SHA384
* ALPN: server did not agree on a protocol. Uses default.
* Server certificate:
*  subject: CN=front-envoy
*  start date: Jul  8 01:31:46 2020 GMT
*  expire date: Jul  6 01:31:46 2030 GMT
*  issuer: CN=front-envoy
*  SSL certificate verify result: self signed certificate (18), continuing anyway.
* using HTTP/1.x
> GET /service/1 HTTP/1.1
> Host: localhost:8443
> User-Agent: curl/8.1.2
> Accept: */*
> 
< HTTP/1.1 200 OK
< content-type: text/plain; charset=utf-8
< content-length: 83
< date: Thu, 02 May 2024 23:55:09 GMT
< server: envoy
< x-envoy-upstream-service-time: 2
< 
Hello Anonymous OPA from behind Envoy 1!
hostname 6c0898c665f1
resolved 172.23.0.3
* Connection #0 to host localhost left intact
```

Temos conexão com o serviço através dos dois protocolos, teste para o `/service/2 `e o resultado deve ser o semelhante.

#

### Load Balance no Envoy

Agora o objetivo será testar a distribuição de carga feita pelo proxy quando temos um microsserviço escalado horizontalmente.

#### Replique um serviço

```bash
docker-compose up -d --scale service1=3
```

#### Execute chamadas ao serviço
Com as réplicas do service funcionando normalmente, teste fazer o GET múltiplas vezes e perceba a mudança no endereco IP.

```bash
curl -v localhost:8080/service/1
```

Exemplos:
```
...
< x-envoy-upstream-service-time: 1
< 
Hello Anonymous OPA from behind Envoy 1!
hostname a9ee19bd28d3
resolved 172.23.0.8
* Connection #0 to host localhost left intact
```
```
...
< x-envoy-upstream-service-time: 1
< 
Hello Anonymous OPA from behind Envoy 1!
hostname a9ee19bd28d3
resolved 172.23.0.9
* Connection #0 to host localhost left intact
```
```
...
< x-envoy-upstream-service-time: 1
< 
Hello Anonymous OPA from behind Envoy 1!
hostname a9ee19bd28d3
resolved 172.23.0.3
* Connection #0 to host localhost left intact
```
#### Teste balanceamento de carga

Para ficar mais claro visualmente, vamos testar com 200 requisicoes:

Primeiro torne o arquivo `lb_count.sh` executável e rode em seguida:
```bash
chmod +x ./extra/lb_count.sh
./extra/lb_count.sh
```
A saída deve ser semelhante a:
```
IP: 172.23.0.8, Quantidade: 67
IP: 172.23.0.9, Quantidade: 67
IP: 172.23.0.3, Quantidade: 66
```
#

### Authorization com Envoy

