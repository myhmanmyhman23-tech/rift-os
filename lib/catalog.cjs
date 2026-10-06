const apps = Object.freeze({
  modrinth: {id:'com.modrinth.ModrinthApp',name:'Modrinth App'},
  steam: {id:'com.valvesoftware.Steam',name:'Steam'},
  lutris: {id:'net.lutris.Lutris',name:'Lutris'},
  bottles: {id:'com.usebottles.bottles',name:'Bottles'}
});
const games = [
  {id:'minecraft',name:'Minecraft',subtitle:'MODRINTH / JAVA',app:'modrinth',kind:'native',tag:'Нативный Linux',symbol:'▦',color:'#9fd785',description:'Твой привычный Modrinth App: модпаки, версии и миры. Вход через Microsoft с лицензионной Java Edition.',steps:['Установить или открыть Modrinth App.','Войти в Microsoft-аккаунт с купленной Java Edition.','Установить модпак или создать свой профиль.'],status:'Linux-версия Modrinth существует. Здесь используется поддерживаемая сообществом сборка Flatpak; модпаки и запуск на этой системе требуют проверки.'},
  {id:'blackmesa',name:'Black Mesa',subtitle:'STEAM / SOURCE',app:'steam',kind:'native',tag:'Нативный Linux',symbol:'λ',color:'#ffac66',description:'Возвращение в комплекс Black Mesa. Установка Linux-версии через твою библиотеку Steam.',steps:['Установить Steam и войти в аккаунт.','Найти Black Mesa в библиотеке.','Установить Linux-версию и проверить запуск.'],status:'Linux-версия доступна в Steam. Производительность на твоём оборудовании ещё не проверена.'},
  {id:'overwatch',name:'Overwatch',subtitle:'BATTLE.NET / WINE',app:'lutris',kind:'experimental',tag:'Требует проверки',symbol:'⌁',color:'#ffc66c',description:'Твой привычный Battle.net. Подготовка Windows-лаунчера через Lutris.',steps:['Установить Lutris.','В Lutris открыть поиск установщиков и выбрать Battle.net.','Пройти установку и войти в Blizzard-аккаунт.','Установить Overwatch в Battle.net и проверить игру.'],status:'Установка Lutris не устанавливает Battle.net или игру. Совместимость лаунчера, обновлений и матчей ещё не проверена.'},
  {id:'genshin',name:'Genshin Impact',subtitle:'HOYOPLAY / WINE',app:'lutris',kind:'experimental',tag:'Экспериментально',symbol:'✧',color:'#bba2ee',description:'Профиль HoYoPlay. Настройка и проверка совместимости через Lutris.',steps:['Установить Lutris.','В Lutris найти установщик Genshin Impact.','Скачать игру через официальный HoYoPlay и войти в аккаунт.','Проверить запуск после актуального обновления.'],status:'Официальная ПК-платформа — Windows. Работоспособность через Wine не подтверждена на этой сборке; обход античита не используется.'}
];
module.exports={apps,games};
