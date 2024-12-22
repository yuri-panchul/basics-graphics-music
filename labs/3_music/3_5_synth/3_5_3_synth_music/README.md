[Назад в оглавление](../README.md)

# Проигрывание простой музыки на звуковом канале
Данная демонстрация показывает проигрывание простой музыки на звуковом канале.

## Описание примера

Данный пример содержит дополнительные модули, обеспечивающие проигрывание последовательностей нот.

### Модуль melody_memory

Данный модуль содержит три счётчика, в совокупности с памятью мелодий формирующие последовательность команд для звукового канала.

Первый счётчик `quant_cnt` выполняет счёт строк памяти мелодий и является указателем на текущую строку.
Инкремент счётчика происходит по условию `( bit_cnt_ff >= bits_to_switch )`, что, как мы увидим далее, эквивалентно фразе "нота отыграла свою длительность".

```verilog
    // pending quant driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        quant_cnt_ff <= 'b0;
      end
      else begin
        if ( bit_cnt_ff >= bits_to_switch ) begin
          quant_cnt_ff <= quant_cnt_ff + 'b1;
        end
        else if ( quant_cnt_ff >= MEMORY_DEPTH ) begin
          quant_cnt_ff <= 'b0;
        end
      end
    end
```


Второй счётчик отвечает за отсчёт времени, в течение которого должна играться нота из памяти мелодий. Шаг счётчика -- 1/8 ноты. Этот счётчик используется для формирования условия переключения `quant_cnt`.

```verilog
    // bit counter driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        bit_cnt_ff <= 'b0;
      end
      else begin
        if ( bit_cnt_ff >= bits_to_switch ) begin
          bit_cnt_ff <= 'b0;
        end
        else if ( tick_cnt_ff >= TPB ) begin
          bit_cnt_ff <= bit_cnt_ff + 'b1;
        end
      end
    end
```

Третий счётчик `tick_cnt` используется для формирования из сигнала тактовой частоты условия "прошло количество времени, эквивалентное 1/8 ноты" и опирается на параметр `TPB`. Обратите внимание, что значение BPM музыки изменяемо и задаётся в виде параметра модуля.

```verilog
    // tick counter driver
    always_ff @( posedge clk_i ) begin
      if ( rst_i ) begin
        tick_cnt_ff <= 'b0;
      end
      else begin
        if ( tick_cnt_ff >= TPB ) begin
          tick_cnt_ff <= 'b0;
        end
        else begin
          tick_cnt_ff <= tick_cnt_ff + 'b1;
        end
      end
    end
```

В файле `music_imperial_march.svh` находится непосредственно таблица с музыкой.

- Старший бит записи в таблице отвечает за то, активен в данный момент генератор звука или нет.
- Следом поле из 4 битов определяет длительность проигрываемого звука в 1/8 ноты
- Далее указана нота, которая должна проигрываться
- Младшие два бита записи выделены для указания октавы

|Нота| Значение |
|-|-|
| C | 0 |
| C# | 1 |
| D | 2 |
| D# | 3 |
| E | 4 |
| F | 5 |
| F# | 6 |
| G | 7 |
| G# | 8 |
| A | 9 |
| A# | 10 |
| B | 11 |


|Октава| Значение |
|-|-|
| Третья | 0 |
| Вторая | 1 |
| Первая | 2 |
| Малая | 3 |



```verilog
always_comb begin
    case(quant_cnt_ff) //  en    1/8   note  octave
        'd0: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd1: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};

        'd2: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd3: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};

        'd4: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd5: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};
  
        'd6: melody_rom = {1'b1, 4'd1, 4'd3, 2'd2};
        'd7: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd8: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd9: melody_rom = {1'b0, 4'd1, 4'd7, 2'd2};

        'd10: melody_rom = {1'b1, 4'd1, 4'd3, 2'd2};
        'd11: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd12: melody_rom = {1'b1, 4'd1, 4'd7, 2'd2};
        'd13: melody_rom = {1'b0, 4'd3, 4'd7, 2'd2};

        'd14: melody_rom = {1'b1, 4'd1, 4'd2, 2'd1};
        'd15: melody_rom = {1'b0, 4'd1, 4'd2, 2'd1};

        'd16: melody_rom = {1'b1, 4'd1, 4'd2, 2'd1};
        'd17: melody_rom = {1'b0, 4'd1, 4'd2, 2'd1};

        'd18: melody_rom = {1'b1, 4'd1, 4'd2, 2'd1};
        'd19: melody_rom = {1'b0, 4'd1, 4'd2, 2'd1};

        'd20: melody_rom = {1'b1, 4'd1, 4'd3, 2'd1};
        'd21: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd22: melody_rom = {1'b1, 4'd1, 4'd6, 2'd2};
        'd23: melody_rom = {1'b0, 4'd1, 4'd6, 2'd2};

        'd24: melody_rom = {1'b1, 4'd1, 4'd3, 2'd2};
        'd25: melody_rom = {1'b1, 4'd1, 4'd10, 2'd2};
        'd26: melody_rom = {1'b1, 4'd3, 4'd7, 2'd2};

        'd27: melody_rom = {1'b0, 4'd8, 4'd0, 2'd0};

        default: melody_rom = {1'b0, 4'd1, 4'd0, 2'd0};
    endcase
end
```


Файл `note_freq_mem.sv` содержит таблицу преобразования нот и октав в параметр `freq` для генератора звука.

Любопытным фактом из мира музыки является то, что последовательность октав меняет частоту звучания ноты ровно в 2 раза. В цифровой схемотехнике для формирования частоты с учётом октавы можно таким образом использовать сдвиги:

```verilog
assign freq_o = freq_unshifted >> octave_sel_i;
```