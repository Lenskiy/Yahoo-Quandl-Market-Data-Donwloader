% Example 1: Download data from Yahoo
initDate = '1-Jan-2014';
symbol = 'GOOGL';
aaplusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
aaplusd_yahoo= timeseries([aaplusd_yahoo_raw.Close, aaplusd_yahoo_raw.High, aaplusd_yahoo_raw.Low], datestr(aaplusd_yahoo_raw(:,1).Date));
aaplusd_yahoo.DataInfo.Units = 'USD';
aaplusd_yahoo.Name = symbol;
aaplusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";

% Example 2: Download data from Quandl
dataset = 'WIKI/GOOGL';
aaplusd_quanl_raw = getMarketDataViaQuandl(dataset, initDate);
aaplusd_quanl= timeseries([aaplusd_quanl_raw.Close, aaplusd_quanl_raw.High, aaplusd_quanl_raw.Low], datestr(aaplusd_quanl_raw(:,1).Date));
aaplusd_quanl.DataInfo.Units = 'USD';
aaplusd_quanl.Name = dataset;
aaplusd_quanl.TimeInfo.Format = "dd-mm-yyyy";


figure('color', 'white'), % note the Quandl returns inaccurate date
subplot(2,1,1), plot(aaplusd_yahoo);
legend({'Close', 'High', 'Low'},'Location', 'northwest');
subplot(2,1,2), plot(aaplusd_quanl);
legend({'Close', 'High', 'Low'},'Location', 'northeast');

% Example 4: Download IBM stock price from Yahoo
initDate = '1-Jan-1962';
symbol = 'IBM';
ibmusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
ibmusd_yahoo= timeseries([ibmusd_yahoo_raw.Close, ibmusd_yahoo_raw.High, ibmusd_yahoo_raw.Low], datestr(ibmusd_yahoo_raw(:,1).Date));
ibmusd_yahoo.DataInfo.Units = 'USD';
ibmusd_yahoo.Name = symbol;
ibmusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";

figure('color', 'white'), plot(ibmusd_yahoo);
legend({'Close', 'High', 'Low'},'Location', 'northwest');

% Example 5: Download OPEC Basket Price from Quandl
dataset = 'OPEC/ORB';
opec_orb_raw = getMarketDataViaQuandl(dataset, initDate, date(), 'weekly');
opec_orb_ts = timeseries(opec_orb_raw.Value, datestr(opec_orb_raw.Date));
opec_orb_ts.DataInfo.Units = 'USD';
opec_orb_ts.Name = dataset;
opec_orb_ts.TimeInfo.Format = "dd-mm-yyyy";
figure('color', 'white'), plot(opec_orb_ts);
legend({'Close'},'Location', 'northwest');

% Example 6: Download NVAX from Yahoo
initDate = '1-Jan-1996';
symbol = 'NVAX';
nvaxusd_yahoo_raw = getMarketDataViaYahoo(symbol, initDate);
nvaxusd_yahoo= timeseries([nvaxusd_yahoo_raw.Open, nvaxusd_yahoo_raw.Close, nvaxusd_yahoo_raw.High, nvaxusd_yahoo_raw.Low], datestr(nvaxusd_yahoo_raw(:,1).Date));
nvaxusd_yahoo.DataInfo.Units = 'USD';
nvaxusd_yahoo.Name = symbol;
nvaxusd_yahoo.TimeInfo.Format = "dd-mm-yyyy";
figure, plot(nvaxusd_yahoo);
legend({'Open', 'Close', 'High', 'Low'},'Location', 'northwest');

% Example 7: Download data from Yahoo and estimate covariance matrix
clear marketData;
initDate = datetime(addtodate(datenum(today),-3,'year'),'ConvertFrom','datenum');
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

