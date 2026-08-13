function data = download_openmeteo_data()

latitude  = 22.4;    % Sundarbans region
longitude = 89.6;

url = sprintf([ ...
'https://archive-api.open-meteo.com/v1/archive?' ...
'latitude=%f&longitude=%f&start_date=2023-01-01&end_date=2023-12-31&' ...
'hourly=temperature_2m,shortwave_radiation'], latitude,longitude);

%url = ['https://re.jrc.ec.europa.eu/api/v5_2/seriescalc?' ...
%       'lat=22.4&lon=89.6&outputformat=json'];

%data = webread(url);

raw = webread(url);

data.time = raw.hourly.time;

data.temperature = raw.hourly.temperature_2m;

data.irradiance = raw.hourly.shortwave_radiation;

end