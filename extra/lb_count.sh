#!/bin/bash

# Defina o número de solicitações a serem enviadas
total_requests=200

# Array para armazenar os IPs
declare -a ip_counts

# Loop para enviar solicitações
for ((i=0; i<total_requests; i++)); do
    # Envie a solicitação e capture o IP
    ip=$(curl -s -v localhost:8080/service/1 2>&1 | awk '/^resolved/ {print $2}')
    
    # Se o IP estiver vazio, continue para a próxima iteração
    if [ -z "$ip" ]; then
        continue
    fi
    
    # Verifique se o IP já está no array e incremente o contador, se necessário
    found=false
    for ((j=0; j<${#ip_counts[@]}; j++)); do
        if [ "${ip_counts[j]}" == "$ip" ]; then
            ((counts[j]++))
            found=true
            break
        fi
    done
    
    # Se o IP não estiver no array, adicione-o com um contador de 1
    if [ "$found" == false ]; then
        ip_counts+=("$ip")
        counts+=(1)
    fi
done

# Exibir contagem de IPs
for ((i=0; i<${#ip_counts[@]}; i++)); do
    echo "IP: ${ip_counts[i]}, Quantidade: ${counts[i]}"
done
