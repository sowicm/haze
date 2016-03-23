function [ output_args ] = plothaze( input_args )

clc;clear;

date = '20160101';
% hour, from 0 to 23
hour = '1';
% type, could be 'PM2.5', 'PM2.5_24h', 'PM10', 'PM10_24h', 'AQI'
%     extra datas (CO2 etc.)
type = 'AQI';
% single, 'off' -- plot 12 hours graph since `hour`
%         'on'  -- plot 1 graph at that `date` and `hour`
single = 'off';
% showname, whether show monitoring names
showname = 'off';
% showvalue, whether show monitoring excat values
showvalue = 'off';

use_mysql = 'off';

if strcmpi(use_mysql, 'on')
    conn = database('104.236.242.31:32769', 'root', 'hazepassw0rd');
else
    conn = database('beijing.sqlite', '', '', 'org.sqlite.JDBC','jdbc:sqlite:/Users/sowicm/Documents/MATLAB/beijing.sqlite');
end;
ping(conn);
cursor = exec(conn, 'select `name`, `longitude`, `dimension` from Points where `state`="beijing";');
cursor = fetch(cursor); %, 35);
points = cursor.Data;
%points = cell2mat(points);
close(cursor);

names = cell(length(points));
lats = zeros(1,length(points));
lons = zeros(1,length(points));

for i = 1:length(points)
    name = char(points{i,1});
    lon = str2double(points{i,2});
    lat = str2double(points{i,3});
    names{i} = name;
    lats(i) = lat;
    lons(i) = lon;
end

names = names';

figure('paperpositionmode', 'auto');

for s = 1:12
    if strcmpi(single, 'off')
        subplot(3, 4, s);
    end;
    
    ax = worldmap([39 42],[115 118]);
    states = shaperead('map/bou2_4p.shp', 'UseGeoCoords', true);
    states_faceColors = makesymbolspec('Polygon',...
        {'INDEX', [1 numel(states)], 'FaceColor', ...
        [1 1 1]}); %polcmap(numel(states))});
    geoshow(ax, states, 'DisplayType', 'polygon', ...
      'SymbolSpec', states_faceColors)

    for i = 1:length(points)
        lat = lats(i);
        lon = lons(i);
        geoshow(lat, lon, 'Marker', '.', 'MarkerEdgeColor', 'red');
        if strcmpi(showname, 'on')
            name = char(points{i,1});
            textm(lat, lon, name);
        end;
    end
    
    cursor = exec(conn, ['select `point`, `value` from AQI where `date`="' date ...
                   '" and hour=' hour ' and type = "' type '";']);
    cursor = fetch(cursor);
    AQIs = cursor.Data;
    close(cursor);

    %disp(length(AQIs));
    %disp(names);
    values = zeros(1, length(AQIs)) * NaN;

    for i = 1:length(AQIs)
        point = char(AQIs{i,1});
        value = AQIs{i,2};
        %disp(point);
        %disp(value);
        %k = find(names == point);
        %k = find(strcmp(names, point));
        %disp(i);
        %disp(k);
        %disp('---');
        %values(k) = value;
        values(i) = value;
    end

    %disp(values);
    %disp(lats);
    %disp(lons);
    %axesm miller;
    %surfm(lats, lons, values);
    %demcmap(values);

    [aa, bb] = meshgrid(lats, lons);
    %zz = griddata(lats, lons, values, aa, bb);

    %save haze aa bb zz

    %zz_padded = [  zeros(1,size(zz,2)+2)
    %                zeros(size(zz,1),1) zz  zeros(size(zz,1),1)
    %                zeros(1,size(zz,2)+2)  ];

    latlim = linspace(39, 42, 500);
    lonlim = linspace(115, 118, 500);
    [xx, yy] = meshgrid(latlim, lonlim);
    %zi = interp2(aa, bb, zz, xx, yy, 'spline')%, 0);
    %surfm(xx, yy, values);
    zz = griddata(lats, lons, values, xx, yy, 'cubic');
    surfm(xx, yy, zz);%zi);
    %shading interp;
    %shading flat;
    %demcmap(values);
    %colorbar;

    if strcmpi(showvalue, 'on')
        for i = 1:length(points)
           lon = lons(i);
           lat = lats(i);
           geoshow(lat, lon, 'Marker', '.', 'MarkerEdgeColor', 'red');
           textm(lat, lon, num2str(values(i)));
        end
    end;

    title(['date: ' date ' ' hour ' ' type]);

    hour = num2str( str2num(hour) + 1 );
    
    if strcmpi(single, 'on')
        break;
    end;
end;

close(conn);

end

