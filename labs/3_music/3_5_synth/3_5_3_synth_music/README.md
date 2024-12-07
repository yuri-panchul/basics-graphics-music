[Назад в оглавление](../README.md)

# Проигрывание простой музыки на звуковом канале
Демонстрация проигрывания простой музыки на звуковом канале находится в папке `audio_synth_practice/3_music`.

## Запуск примера

Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/3_music
do make.do
```

или выберите в Vivado `tb_music` как Top Level.

## Описание примера

Данный пример отличается от предыдущего только тестбенчем.

Тестбенч содержит управляющую последовательность, генерирующую простую музыку на одном звуковом канале.

```verilog

  // Action sequence
  initial begin
    channel_gen_sel = 3'd4;
    channel_volume  = 16'hff;

    channel_en   = '1;
    channel_freq = G4_FREQ;
    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '0;

    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '1;
    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '0;

    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '1;
    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '0;

    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '1;
    channel_freq = Dd4_FREQ;

    repeat(CYCLE/8) @(posedge clk);
    channel_freq = Ad4_FREQ;

    repeat(CYCLE/8) @(posedge clk);
    channel_freq = G4_FREQ;
    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '0;

    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '1;
    channel_freq = Dd4_FREQ;

    repeat(CYCLE/8) @(posedge clk);
    channel_freq = Ad4_FREQ;

    repeat(CYCLE/8) @(posedge clk);
    channel_freq = G4_FREQ;
    repeat(CYCLE/8) @(posedge clk);
    channel_en   = '0;


  end
```
