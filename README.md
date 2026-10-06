# RIFT OS — 0.2.0-alpha.1

Игровой Linux на основе **Kubuntu 24.04.5 LTS x86_64**: центр управления, профиль сборки ISO и автоматизированные prerelease-релизы на GitHub. Первый образ считается собранным только после успешного выполнения workflow **Build RIFT OS ISO**; исходный код и скрипты сами по себе не подтверждают загрузку образа.

Minecraft запускается через **Modrinth App** с лицензионным Microsoft-аккаунтом. Для Overwatch используется **Battle.net** через Lutris.

Подробности сборки, проверки и скачивания частей ISO: [build/README.md](build/README.md). Заметки релиза: [release/NOTES.md](release/NOTES.md).

## Предпросмотр в Windows

Нужен Node.js 18 или новее, внешних зависимостей для запуска нет:

```sh
node server.cjs
```

Открыть адрес из терминала, обычно `http://127.0.0.1:4180`. Остановить сервер — Ctrl+C. В Windows доступны интерфейс и данные CPU/памяти; установки и запуск Linux-приложений заблокированы. Данные не отправляются на внешний сервер.

## Подготовка Linux

Эти команды меняют пакеты установленной системы. **На текущем Windows-компьютере они не выполнялись.** Прочитать план без изменений:

```sh
bash linux/bootstrap.sh --plan
bash linux/setup.sh --plan
```

Когда будет выбрана среда для испытаний, в Ubuntu/Kubuntu 24.04:

```sh
sudo bash linux/bootstrap.sh
bash linux/setup.sh
```

Опция `--desktop` у bootstrap дополнительно устанавливает KDE. По умолчанию существующий рабочий стол сохраняется. Для установки всех четырёх лаунчеров сразу: `bash linux/setup.sh --launchers`.

Системная подготовка добавляет i386-библиотеки, графические библиотеки Mesa/Vulkan, прошивки, диагностические инструменты, Flatpak и Node.js. При обнаружении NVIDIA используется `ubuntu-drivers install`. Возможны необходимость перезагрузки и регистрация ключа Secure Boot; скрипт не перезагружает компьютер сам и не отключает Secure Boot.

Пользовательская подготовка регистрирует Flathub, копирует центр в `~/.local/share/rift-os` и добавляет ярлык в меню. Сервис запускается локально при открытии ярлыка, не от root. Последующее добавление пакетов Flatpak происходит для текущего пользователя. Лаунчеры не входят в репозиторий, для их загрузки нужен интернет.

## Профили

| Игра | Среда | Статус |
| --- | --- | --- |
| Minecraft Java | Modrinth App | Linux-клиент есть; нужна купленная Java Edition |
| Black Mesa | Steam | Linux-версия есть; нужно испытание на железе |
| Overwatch | Battle.net через Lutris/Wine | Экспериментально, не проверено |
| Genshin Impact | HoYoPlay через Lutris/Wine | Экспериментально, не проверено |

Кнопка установки ставит **лаунчер**, а не игру. Minecraft и Blizzard-аккаунты вводятся в самих лаунчерах. RIFT OS не хранит пароли. Battle.net/HoYoPlay устанавливаются внутри Lutris по шагам профиля. Мастер EXE открывает Bottles и объясняет выбор файла внутри приложения; импорт и управление собственными Windows-играми из RIFT OS ещё не реализованы.

## Проверки

```sh
npm test
```

Браузерные проверки требуют Playwright и Chromium/Edge/Chrome:

```sh
npm install --no-save playwright
npx playwright install chromium
npm run test:ui
```

Можно задать `PLAYWRIGHT_PATH` и `BROWSER_PATH`. Артефакты сохраняются в `artifacts/`. Тесты Linux-команд используют подмену исполнителя: это подтверждает логику, но не заменяет запуск на Linux.

## Границы текущей версии

- Профиль сборки ISO, первая подготовка драйверов и базовое оформление KDE реализованы. Проверка реального рабочего стола, загрузчика и установки на диск ещё требуется.
- Linux-подготовка написана, но не проверена на настоящей Linux-системе.
- Не обещается работа любой Windows-игры; обход античита не предусмотрен.
- Прямой запуск Overwatch/Genshin, игровые настройки, копии сохранений и обновления ОС — последующие этапы.
- Центр обнаруживает лаунчеры Flatpak; системные пакеты и другие установки пока не учитываются.
- Журнал установок хранится в памяти до перезапуска центра. Диагностика обновляется по кнопке.

## Источники

- [NVIDIA в Ubuntu](https://ubuntu.com/server/docs/how-to/graphics/install-nvidia-drivers/)
- [Modrinth App для Linux](https://modrinthlauncher.org/download/linux/)
- [Lutris](https://lutris.net/downloads)
- [Bottles](https://docs.usebottles.com/advanced/cli)
- [Minecraft editions](https://help.minecraft.net/hc/en-us/articles/360034753992)
- [Black Mesa в Steam](https://store.steampowered.com/app/362890/Black_Mesa/)
- [Genshin: официальные требования](https://support.hoyoverse.com/hc/en-us/articles/52089402685593-What-are-the-system-requirements-to-play-Genshin-Impact)
