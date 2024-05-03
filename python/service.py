from aiohttp import web
import logging
import os
import socket

routes = web.RouteTableDef()
cache_storage = {}

@routes.get("/{service_type}/{service}")
async def get(request):
    service_type = request.match_info["service_type"]
    service = request.match_info["service"]
    service_name = os.environ.get("SERVICE_NAME")

    if service_name and service != service_name:
        raise web.HTTPNotFound()
    
    nickname = "Anonymous"
    if service_type in cache_storage:
        nickname = cache_storage[service_type]["nickname"]
    
    return web.Response(text=(
        f"Hello {nickname} {request.headers.get('x-current-user')} from behind Envoy {service}!\n"
        f"hostname {socket.gethostname()}\n"
        f"resolved {socket.gethostbyname(socket.gethostname())}\n"))

@routes.post("/{service_name}/{service}")
async def set_nickname(request):
    service_name = request.match_info["service_name"]
    service = request.match_info["service"]
    data = await request.json()
    nickname = data.get("nickname") + "-" + service

    if service_name in cache_storage:
        cache_storage[service_name]["nickname"] = nickname
    else:
        cache_storage[service_name] = {"nickname": nickname}

    return web.Response(text=f"Hello, {nickname}!")


if __name__ == "__main__":
    app = web.Application()
    logging.basicConfig(level=logging.DEBUG)
    app.add_routes(routes)
    web.run_app(app, host='0.0.0.0', port=8080)