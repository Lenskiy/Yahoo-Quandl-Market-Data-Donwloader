% Example 1: Download data from Yahoo
initDate = '1-Jan-2014';
symbol = 'AAPL';
aaplusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
aaplusd_yahoo= timeseries([aaplusd_yahoo_raw.Close, aaplusd_yahoo_raw.High, aaplusd_yahoo_raw.Low], datestr(aaplusd_yahoo_raw(:,1).Date));
aaplusd_yahoo.DataInfo.Units = 'USD';
aaplusd_yahoo.Name = symbol;
aaplusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";

% Example 2: Download data from Quandl
dataset = 'WIKI/AAPL';
aaplusd_quanl_raw = getMarketDataViaQuandl(dataset, initDate);
aaplusd_quanl= timeseries([aaplusd_quanl_raw.Close, aaplusd_quanl_raw.High, aaplusd_quanl_raw.Low], datestr(aaplusd_quanl_raw(:,1).Date));
aaplusd_quanl.DataInfo.Units = 'USD';
aaplusd_quanl.Name = dataset;
aaplusd_quanl.TimeInfo.Format = "dd-mm-yyyy";


figure, % note the Quandl returns inaccurate date
subplot(2,1,1), plot(aaplusd_yahoo);
legend({'Close', 'High', 'Low'},'Location', 'northwest');
subplot(2,1,2), plot(aaplusd_quanl);
legend({'Close', 'High', 'Low'},'Location', 'northeast');




% Example 3: Download data from Yahoo and estimate covariance matrix
clear marketData;
initDate = datetime(addtodate(datenum(today),-1,'year'),'ConvertFrom','datenum');
symbols = {'^GSPC', 'DAX',  '^N225', 'GLD', 'QQQ', '^IXIC', 'FNCL', 'BTC-USD'};

for k = 1:length(symbols)
    data = getMarketDataViaYahoo(symbols{k}, initDate);
    ts(k) = timeseries(data.Close, datestr(data(:,1).Date));
    tsout = resample(ts(k),ts(1).Time);
    marketData(:,k) = tsout.Data;
end

marketData(isnan(marketData)) = 0; % In case resample() introduced NaNs
normalizedPrice = (marketData - mean(marketData))./std(marketData);
normalizedPrice = normalizedPrice - normalizedPrice(1,:);
tscomb = timeseries(normalizedPrice);
tscomb.TimeInfo = ts(1).TimeInfo;
tscomb.Name = 'normalized';
tscomb.TimeInfo.Format = "dd-mm-yyyy";
figure, plot(tscomb);
legend(symbols, 'interpreter', 'none', 'Location', 'best');

covMat = corrcoef(marketData);
covMat(eye(8) == 1) = 0;

figure, heatmap(covMat,'Colormap', parula(3), 'ColorbarVisible', 'on');
ax = gca;
ax.XData = symbols;
ax.YData = symbols;
