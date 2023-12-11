module m;

localparam N = 4;
logic [3:0] cnt = '1;

initial
begin
    $display ( "1        %b", 1        );
    $display ( "'d1      %b", 'd1      );
    $display ( "1'd1     %b", 1'd1     );
    $display ( "4'd1     %b", 4'd1     );
    $display ( "4' ('d1) %b", 4' ('d1) );
    $display ( "N' ('d1) %b", N' ('d1) );
    $display ( "'1       %b", '1       );

    $display ( "cnt + 1        %b", cnt + 1        );
    $display ( "cnt + 'd1      %b", cnt + 'd1      );
    $display ( "cnt + 1'd1     %b", cnt + 1'd1     );
    $display ( "cnt + 4'd1     %b", cnt + 4'd1     );
    $display ( "cnt + 4' ('d1) %b", cnt + 4' ('d1) );
    $display ( "cnt + N' ('d1) %b", cnt + N' ('d1) );
    $display ( "cnt + '1       %b", cnt + '1       );
end

endmodule
