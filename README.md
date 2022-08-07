# Проект, который я сделал для прикола

Это читалка новостных лент (rss и atom). Я использую ее, чтобы узнать что нового запостили на Хабре, VC, rutracker, и т.д. Моей целью было создать простой интерфейс, который позволил бы быстро с клавиатуры просмотреть подписки, удалить прочитанное, а интересное отложить в избранное.

![big-light](https://user-images.githubusercontent.com/2874327/183303390-9437c8d6-9976-4938-82f9-c9b87a8225fa.png)

Навигация клавишами «↑» и «↓», удалить — «del», добавить в избранное — «f», забанить категорию — «b». Когда записи кончаются, загружаются следующие 10.

Серверная часть сделана на Crystal. Я выбрал этот язык, потому что хотелось использовать мой любимый Ruby-подобный синтаксис и не хотелось держать интерпретатор с окружением ради такой мелочи. В итоге получилась пара бинарников без внешних зависимостей.

Первый запускается по крону, скачивает ленты, парсит данные и складывает их в базу данных sqlite.

Второй реализует web-сервер, который отдает статику и данные через REST API.

Клиентская часть — это приложение на Vue.js всего с парой компонентов.

Как полагается, есть темная тема оформления.

![dark-and-light](https://user-images.githubusercontent.com/2874327/183303429-3e359cf5-1adb-412b-a74c-d0ace8d33ecb.png)

Все вместе собирается в образ Docker на основе Alpine Linux, размером всего 19Мб. У меня он работает на локальной машине.

Демо: http://feedread.up.railway.app (из РФ нужен VPN)

## Установка и запуск

    docker pull kereal/feedread
    docker run -idt --name feedread -p 3008:80 kereal/feedread
    open http://localhost:3008

По всем вопросам пишите на kereal@gmail.com
