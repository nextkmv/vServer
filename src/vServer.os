﻿
// РАЗДЕЛ СВОЙСТВ КЛАССА
Перем Версия Экспорт;
Перем Хост Экспорт;
Перем Порт Экспорт;
Перем TCPСервер;
Перем Таймаут;
Перем СтатусыHTTP;
Перем СоответствиеРасширенийТипамMIME;

// РАЗДЕЛ МЕТОДОВ КЛАССА
Процедура Инициализировать() Экспорт
	Версия 	= "0.0.1";
	Хост = "http://localhost/";
	Порт = 1234;
	Таймаут = 1;
КонецПроцедуры 

// Разбирает вошедший запрос и возвращает объект запроса
Функция РазобратьЗапросКлиента(ТекстовыеДанные)
	Запрос = Новый vHttpЗапрос();
	Запрос.ТекстЗапроса = ТекстовыеДанные;
	Запрос.Инициализировать();
	Возврат Запрос;
КонецФункции

Функция ОбработатьЗапросКлиента(Запрос, Ответ)
	
	// Разбор маршрута
	Если Запрос.ИмяКонтроллера = "resource" Тогда
		// Задел для файловых ресурсов
		//Сообщить("Обработка ресурсов не реализована");
		//Попытка
			ПутьКФайлу = Запрос.Заголовок.Получить("Path");
			ИмяФайла = ТекущийКаталог()+"\"+ПутьКФайлу;
			ИмяФайла = СтрЗаменить(ИмяФайла,"/","\");
			//Сообщить(ИмяФайла);
			//Сообщить("__");
		Попытка
			Файл = Новый Файл(ИмяФайла);
		Исключение
			Контроллер = Новый КонтроллерDefault();
			Контроллер.Ошибка404(Запрос,Ответ);
			Возврат Ложь;
		КонецПопытки;

		Если НЕ Файл.Существует() Тогда
			Контроллер = Новый КонтроллерDefault();
			Контроллер.Ошибка404(Запрос,Ответ);
			Возврат Ложь;
		Иначе
			Расширение = Файл.Расширение;
			MIME = СоответствиеРасширенийТипамMIME.Получить(Расширение);
			Если MIME = Неопределено Тогда
				MIME = СоответствиеРасширенийТипамMIME.Получить("default");
			КонецЕсли;
			ЕстьДвоичныеДанные = Ложь;
			Если Найти(MIME,"text") > 0 Тогда
				ДанныеФайла = Новый ЧтениеТекста(СокрЛП(ИмяФайла),КодировкаТекста.UTF8);				
				Размер		= Файл.Размер();
				Ответ.ТекстОтвета = ДанныеФайла.Прочитать();
			Иначе
				ДвоичныеДанные = Новый ДвоичныеДанные(СокрЛП(ИмяФайла));
				Размер		= Файл.Размер();
				Ответ.ДвоичныеДанныеОтвета = ДвоичныеДанные;
			КонецЕсли;			
			//Сообщить(ИмяФайла);
			Ответ.Заголовок.Вставить("Content-Type",MIME);
			Ответ.Заголовок.Вставить("Content-Length",Размер);
						
		КонецЕсли;
	Иначе
		// Обработка запроса роутером
		Роутер = Новый vHttpRouter();
		Попытка
			Роутер.Перенаправить(Запрос,Ответ);
		Исключение
			Ответ.СтатусОтвета = 500;
			Сообщить(ОписаниеОшибки());
		КонецПопытки;
	КонецЕсли;
	//Ответ.ТекстОтвета = ИсходящиеДанные;
КонецФункции

Процедура ОбработатьОтветСервера(Запрос, Ответ,Соединение)
	ПС = Символы.ВК+Символы.ПС;
	мЗаголовок = СокрЛП(СтатусыHTTP[Число(Ответ.СтатусОтвета)])+ПС;
	Соединение.ОтправитьСтроку(мЗаголовок);
	ТекстОтветаКлиенту = "";
	Для Каждого СтрокаЗаголовкаответа из Ответ.Заголовок Цикл
		ТекстОтветаКлиенту = ТекстОтветаКлиенту + СтрокаЗаголовкаответа.Ключ + ":"+ СтрокаЗаголовкаответа.Значение+ПС;
	КонецЦикла;
	//ТекстОтветаКлиенту = ТекстОтветаКлиенту + "Content-Length:"+Строка((СтрДлина(Ответ.ТекстОтвета)-2)*2)+ПС+ПС;
	Соединение.ОтправитьСтроку(ТекстОтветаКлиенту);
	
	Соединение.ОтправитьСтроку(ПС);
	Если НЕ Ответ.ДвоичныеДанныеОтвета = Неопределено Тогда
			Соединение.ОтправитьДвоичныеДанные (Ответ.ДвоичныеДанныеОтвета);
	Иначе
		Соединение.ОтправитьСтроку(СокрЛП(Ответ.ТекстОтвета));
	КонецЕсли;
	//Сообщить(Ответ.ТекстОтвета);
КонецПроцедуры

Процедура Слушать() Экспорт
	Сообщить(СокрЛП(ТекущаяДата())+" - Запуск HTTP сервера на порту:"+СокрЛП(Порт));
	TCPСервер = Новый TCPСервер(Порт);
	TCPСервер.Запустить();
	Сообщить(СокрЛП(ТекущаяДата())+" - Сервер запущен");
	Попытка
			Соединение = TCPСервер.ОжидатьСоединения(Таймаут);
			Пока Истина Цикл
					Если Соединение = Неопределено Тогда
							Соединение = TCPСервер.ОжидатьСоединения(Таймаут);
					Иначе
						ТекстовыеДанныеВходящие		= Соединение.ПрочитатьСтроку();
						//Сообщить(ТекстовыеДанныеВходящие);
						Запрос			  			= РазобратьЗапросКлиента(ТекстовыеДанныеВходящие);						
						Ответ			 			= Новый vHttpОтвет();
						ОбработатьЗапросКлиента(Запрос, Ответ);
						Попытка
							ОбработатьОтветСервера(Запрос,Ответ,Соединение);						
							Сообщить(СокрЛП(ТекущаяДата())+" <- "+СокрЛП(Ответ.СтатусОтвета));
							Соединение.Закрыть();
						Исключение
							Сообщить(СокрЛП(ТекущаяДата())+" <-408 Request Timeout Клиент разорвал соединение");
						КонецПопытки;
						Соединение 					= Неопределено;
						Ответ			 			= Неопределено;
						Запрос						= Неопределено;
						Соединение = TCPСервер.ОжидатьСоединения(Таймаут);
					КонецЕсли;
				КонецЦикла;
		Исключение
			Сообщить("Ошибка при обработке запроса");
			Сообщить(ОписаниеОшибки());
		КонецПопытки;
		
КонецПроцедуры

// РАЗДЕЛ КОНСТРУКТОРА КЛАССА
Инициализировать();
СтатусыHTTP = Новый Массив(1000);
СтатусыHTTP.Вставить(200,"HTTP/1.1 200 OK");
СтатусыHTTP.Вставить(400,"HTTP/1.1 400 Bad Request");
СтатусыHTTP.Вставить(401,"HTTP/1.1 401 Unauthorized");
СтатусыHTTP.Вставить(402,"HTTP/1.1 402 Payment Required");
СтатусыHTTP.Вставить(403,"HTTP/1.1 403 Forbidden");
СтатусыHTTP.Вставить(404,"HTTP/1.1 404 Not Found");
СтатусыHTTP.Вставить(405,"HTTP/1.1 405 Method Not Allowed");
СтатусыHTTP.Вставить(406,"HTTP/1.1 406 Not Acceptable");
СтатусыHTTP.Вставить(500,"HTTP/1.1 500 Internal Server Error");
СтатусыHTTP.Вставить(501,"HTTP/1.1 501 Not Implemented");
СтатусыHTTP.Вставить(502,"HTTP/1.1 502 Bad Gateway");
СтатусыHTTP.Вставить(503,"HTTP/1.1 503 Service Unavailable");
СтатусыHTTP.Вставить(504,"HTTP/1.1 504 Gateway Timeout");
СтатусыHTTP.Вставить(505,"HTTP/1.1 505 HTTP Version Not Supported");

СоответствиеРасширенийТипамMIME = Новый Соответствие();
СоответствиеРасширенийТипамMIME.Вставить(".css","text/css");
СоответствиеРасширенийТипамMIME.Вставить(".js","text/javascript");
СоответствиеРасширенийТипамMIME.Вставить(".jpg","image/jpeg");
СоответствиеРасширенийТипамMIME.Вставить(".jpeg","image/jpeg");
СоответствиеРасширенийТипамMIME.Вставить(".png","image/png");
СоответствиеРасширенийТипамMIME.Вставить(".gif","image/gif");
СоответствиеРасширенийТипамMIME.Вставить(".ico","image/x-icon");
СоответствиеРасширенийТипамMIME.Вставить(".zip","application/x-compressed");
СоответствиеРасширенийТипамMIME.Вставить(".rar","application/x-compressed");

СоответствиеРасширенийТипамMIME.Вставить("default","text/plain");



