# weather-microservice

This microservice polls the "here.com" weather API and posts the data to the weather/zip/status/identifier MQTT topic.

To use this, you need to sign up at here.com for an APPLICATION ID and an APPLICATION CODE and set the ENV variables
WEATHER_APP_ID, WEATHER_APP_CODE, METRIC

The METRIC ENV variable is common among the microservices and indicates whether data are converted to metric or are
presented not metric.

