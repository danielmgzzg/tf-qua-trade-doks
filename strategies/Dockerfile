FROM freqtradeorg/freqtrade:stable

# Copy strategy package into freqtrade user_data path
COPY freqtrade_strategies /freqtrade/user_data/strategies/src

# Make sure package is importable
RUN touch /freqtrade/user_data/strategies/freqtrade_strategies/__init__.py
