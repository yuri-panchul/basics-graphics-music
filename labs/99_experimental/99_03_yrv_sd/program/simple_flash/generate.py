def generate_verilog_hex(input_file):
    with open(input_file, 'rb') as f:
        data = bytearray(f.read())

    # Добиваем до 512 байт (128 строк по 4 байта), чтобы заполнить [0:127]
    while len(data) < 512:
        data.append(0x00)

    for i in range(4):
        with open(f'mcu_mem_bank{i}.hex', 'w') as f:
            # Выбираем каждый 4-й байт, начиная с i
            bank_data = data[i::4]
            for byte in bank_data:
                f.write(f"{byte:02x}\n")
    
    print(f"Готово: Создано 4 файла по 128 байт.")

if __name__ == "__main__":
    generate_verilog_hex('main.bin')