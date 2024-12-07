[Назад в оглавление](../README.md)

# Звуковой канал
Звуковой канал находится в папке `audio_synth_practice/2_audio_channel`.

## Запуск примера

Чтобы запустить пример, выполните в консоли Modelsim/Questa:
```
cd audio_synth_practice/2_audio_channel
do make.do
```

или выберите в Vivado `tb_audio_channel` как Top Level.

## Описание примера

Звуковой канал представляет из себя объединение всех генераторов звука из первой части с логикой их выбора и логикой управления громкостью (реализована с использованием умножения).

```verilog
  audio_square i_square_gen(
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_square)
  );

  audio_saw i_saw_gen(
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_saw)
  );

  audio_saw_inv i_saw_inv_gen(
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_saw_inv)
  );

  audio_triangle i_triangle_gen(
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_triangle)
  );

  audio_sine i_sine_gen(
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_sine)
  );

  audio_noise i_noise_gen(
    .clk_i         (clk_i),
    .rstn_i        (rstn_i),
    .freq_i        (freq_i),
    .sample_data_o (sample_noise)
  );


  always_comb begin
    case(gen_sel_i)
      SEL_SQUARE:   sample_mux = sample_square;
      SEL_SAW:      sample_mux = sample_saw;
      SEL_SAW_INV:  sample_mux = sample_saw_inv;
      SEL_TRIANGLE: sample_mux = sample_triangle;
      SEL_SINE:     sample_mux = sample_sine;
      SEL_NOISE:    sample_mux = sample_noise;
      default:      sample_mux = sample_square;
    endcase
  end

```

При этом, так как результат умножения двух 8 бит чисел имеет разрядность 16 бит, мы хотим использовать старшие 8 бит и отбросить младшие 8 бит. Эта операция выполняется конструкцией `assign sample_final = sample_volume_applied >> 8;`



```verilog
  assign sample_volume_applied = sample_mux * volume_i;
  assign sample_final          = sample_volume_applied >> 8;
```

Также, когда звуковой канал отключен с помощью сигнала `en_i`, необходимо подавать на сигнальный выход нулевое значение.

```verilog
  assign sample_data_o = {8{en_i}} & sample_final;
```


Тестбенч содержит последовательность, в которой все генераторы звукового канала переключаются каждую секунду.

```verilog
  // Action sequence
  initial begin
    channel_en = '1;
    channel_gen_sel = 3'd0;
    channel_freq = 16'd4723; // set 440 Hz frequency
    channel_volume = 16'hff;

    repeat(12500000) @(posedge clk);
    channel_gen_sel = 3'd1;
    repeat(12500000) @(posedge clk);
    channel_gen_sel = 3'd2;
    repeat(12500000) @(posedge clk);
    channel_gen_sel = 3'd3;
    repeat(12500000) @(posedge clk);
    channel_gen_sel = 3'd4;
    repeat(12500000) @(posedge clk);
    channel_gen_sel = 3'd5;
    repeat(12500000) @(posedge clk);

  end
```
