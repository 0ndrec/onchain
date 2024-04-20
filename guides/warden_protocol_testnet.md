### Warden Protocol

Warden Protocol представляет собой модульную инфраструктуру блокчейна первого уровня, разработанную для приложений, работающих в различных блокчейнах (OApps). Эта платформа предлагает значительные преимущества в разработке и безопасности блокчейн-приложений:

1. **Модульная безопасность**: Протокол позволяет разработчикам использовать различные модели безопасности для одних и тех же приложений, минимизируя фрагментацию безопасности и позволяя пользователям выбирать уровень доверия к приложениям.
2. **Омничейн интероперабельность**: Warden Protocol обеспечивает беспрецедентную межцепочечную совместимость, позволяя приложениям взаимодействовать через разные блокчейны без изоляции и фрагментации экосистем.
3. **Абстракция цепочек**: Платформа позволяет приложениям взаимодействовать с любыми другими блокчейнами, что открывает новые возможности для создания и использования приложений.
4. **Универсальные пространства**: Пользователи могут взаимодействовать с различными блокчейнами с помощью уникальных идентификаторов, что упрощает многоцепочечные взаимодействия и повышает удобство использования.

### Руководство по запуску валидатора Warden Protocol

#### Настройка сервера
1. **Обновление системы и установка зависимостей**:
   ```
   sudo apt update
   sudo apt upgrade -y
   sudo apt install -y curl git jq lz4 build-essential
   ```

2. **Установка Go**:
   ```
   sudo rm -rf /usr/local/go
   curl -L https://go.dev/dl/go1.21.6.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
   echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
   source .bash_profile
   ```

#### Установка узла
1. **Клонирование репозитория и настройка**:
   ```
   cd $HOME && rm -rf wardenprotocol
   git clone https://github.com/warden-protocol/wardenprotocol
   cd wardenprotocol
   git checkout v0.3.0
   make install-wardend
   ```

2. **Конфигурация клиента и инициализация узла**:
   ```
   wardend config set client chain-id buenavista-1
   wardend config set client keyring-backend test
   wardend config set client node tcp://localhost:26657
   wardend init "Your Node Name" --chain-id buenavista-1
   ```

3. **Настройка файлов начальной загрузки и конфигурации**:
   ```
   curl -L https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/genesis.json > $HOME/.warden/config/genesis.json
   curl -L https://snapshots-testnet.nodejumper.io/wardenprotocol-testnet/addrbook.json > $HOME/.warden/config/addrbook.json
   ```

4. **Настройка сидов и минимальной цены газа**:
   ```
   sed -i -e 's|^seeds *=.*|seeds = "ddb4d92ab6eba8363bab2f3a0d7fa7a970ae437f@sentry-1.buenavista.wardenprotocol.org:26656,c717995fd56dcf0056ed835e489788af4ffd8fe8@sentry-2.buenavista.wardenprotocol.org:26656,e1c61de5d437f35a715ac94b88ec62c482edc166@sentry-3.buenavista.wardenprotocol.org:26656"|' $HOME/.warden/config/config.toml
   sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.01uward"|' $HOME/.warden/config/app.toml
   ```

5. **Запуск и мониторинг узла**:
   ```
   sudo systemctl start wardend.service
   sudo journalctl -u wardend.service -f --no-hostname -o cat
   ```
6. **В Discord сообществе можно запросить ссылки на снепшоты**:
   https://discord.gg/NaJGzPkH

### ⭐ Убедитесь, что ваш узел синхронизирован с сетью, прежде чем регистрировать валидатора!


#### Генерация ключей
Первым шагом в настройке валидатора является создание и настройка криптографических ключей, которые будут использоваться для подписи блоков:

1. **Создание нового ключа**:
   ```
   wardend keys add <your-validator-name>
   ```

2. **Импорт существующего ключа** (если у вас уже есть ключ, который вы хотите использовать):
   ```
   wardend keys import <your-validator-name> <path-to-your-key-file>
   ```

#### Добавление ключа валидатора
После создания ключей, необходимо инициализировать узел с ключом валидатора:

```
wardend init --chain-id=buenavista-1 --moniker="<your-node-name>" --validator-key=<your-validator-key-name>
```

#### Регистрация в качестве валидатора
После настройки ключа валидатора и подготовки узла, необходимо зарегистрировать узел в качестве валидатора в сети:

1. **Подготовьте стартовый депозит**. Это количество токенов, которое будет заложено в качестве залога (stake):

   ```
   wardend tx staking create-validator \
     --amount=<amount-of-your-token>uward \
     --pubkey=$(wardend tendermint show-validator) \
     --moniker="<your-node-name>" \
     --chain-id=buenavista-1 \
     --commission-rate="0.10" \
     --commission-max-rate="0.20" \
     --commission-max-change-rate="0.01" \
     --min-self-delegation="1" \
     --gas="auto" \
     --gas-prices="0.025uward" \
     --from=<your-validator-key-name>
   ```

   Указывайте комиссию, максимальную комиссию, максимальную изменяемость комиссии, минимальную самоделегацию и другие параметры согласно вашей стратегии управления валидатором.

#### Мониторинг и управление
После регистрации валидатора важно настроить мониторинг и управление:

1. **Проверка статуса вашего валидатора**:
   ```
   wardend query staking validator $(wardend keys show <your-validator-key-name> -a --bech val)
   ```

2. **Мониторинг логов** для отслеживания работы узла и операций валидатора:
   ```
   journalctl -u wardend -f
   ```

#### Важные замечания
- Регулярно обновляйте программное обеспечение узла, чтобы обеспечить совместимость с текущими требованиями сети.
- Следите за обновлениями в сетевой политике и параметрах комиссий для поддержания конкурентоспособности вашего валидатора.

