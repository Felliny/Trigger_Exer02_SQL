create database TriggerJogos
go
use TriggerJogos

drop database TriggerJogos

create table times (
    codigo      int         not null ,
    nome        varchar(40) not null ,
    primary key (codigo)
)
go
create table jogos (
    codigo          int     not null ,
    codigo_time1    int     not null ,
    codigo_time2    int     not null ,
    set_time1       int     not null ,
    set_time2       int     not null ,
    primary key (codigo),
    foreign key (codigo_time1) references times(codigo),
    foreign key (codigo_time2) references times(codigo)
)


insert into times
values
    (0, 'Little Giants'),
    (1, 'Pain')



-- Considera-se vencedor o time que fez 3 de 5 sets.
-- Se a vitória for por 3 x 2, o time vencedor ganha 2 pontos e o time perdedor ganha 1.
-- Se a vitória for por 3 x 0 ou 3 x 1, o vencedor ganha 3 pontos e o perdedor, 0.

-- Fazer uma UDF que apresente:
-- (Nome Time | Total Pontos | Total Sets Ganhos | Total Sets Perdidos | Set Average (Ganhos - perdidos))

create function fn_timeresumo()
returns @tabela table (
    nome_time           varchar(40),
    total_pontos        int,
    total_sets_ganhos   int,
    total_sets_perdidos int,
    average             int
)
begin
    declare @pontos     int,
            @ganho      int,
            @perdido    int,
            @set1        int,
            @set2        int,
            @nome       varchar(40),
            @codigo_time int,
            @count      int,
            @count2     int

    set @pontos = 0
    set @ganho = 0
    set @perdido = 0
    set @count = 0
    set @count2 = 0
    set @codigo_time = 0
    while (@codigo_time is not null )
    begin
        set @codigo_time = (select codigo from times where codigo = @count)
        set @nome = (select nome from times where codigo = @count)

        set @count2 = (select count(codigo) from jogos)

        while (@count2 > 0)
        begin
            set @set1 = (select set_time1 from jogos where codigo_time1 = @codigo_time and codigo = @count2)
            set @set2 = (select set_time2 from jogos where codigo_time2 = @codigo_time and codigo = @count2)

            if (@set1 = 3 or @set2 = 3)
            begin
                set @ganho = @ganho + 1
            end
            else
            begin
                set @perdido = @perdido + 1
            end

            if (@set1 is not null )
            begin
                set @set2 = (select set_time2 from jogos where codigo = @count2)

                if (@set1 = 3 and @set2 = 2)
                begin
                    set @pontos = @pontos + 2
                end
                if (@set1 = 3 and @set2 = 1 or @set2 = 0)
                begin
                    set @pontos = @pontos + 3
                end
                if (@set1 = 2 and @set2 = 3)
                begin
                    set @pontos = @pontos + 1
                end
            end
            else
            begin
                set @set1 = (select set_time1 from jogos where codigo = @count2)

                if (@set2 = 3 and @set1 = 2)
                begin
                    set @pontos = @pontos + 2
                end
                if (@set2 = 3 and @set1 = 1 or @set1 = 0)
                begin
                    set @pontos = @pontos + 3
                end
                if (@set2 = 2 and @set1 = 3)
                begin
                    set @pontos = @pontos + 1
                end
            end

            set @count2 = @count2 - 1
        end
        if (@nome is not null)
        begin
            insert into @tabela
            values
            (@nome, @pontos, @ganho, @perdido, @ganho - @perdido)
        end

        set @perdido = 0
        set @ganho = 0
        set @pontos = 0

        set @count = @count + 1
    end

    return
end

select * from fn_timeresumo()



-- Fazer uma trigger que verifique se os inserts dos sets estão corretos (Máximo 5 sets, sendo que o
-- vencedor tem no máximo 3 sets)

create trigger t_insejogos on jogos
after insert
as
begin
    declare @set01 int,
            @set02 int

    set @set01 = (select inserted.set_time1 from inserted)
    set @set02 = (select inserted.set_time2 from inserted)

    if (@set01 + @set02 <= 5)
    begin
        if (@set01 != 3 and @set02 < 3)
        begin
            rollback transaction
            raiserror (N'Sets inválidos!', 16, 1)
        end
        if (@set01 < 3 and @set02 != 3)
        begin
            rollback transaction
            raiserror (N'Sets inválidos!', 16, 1)
        end
    end
    else
    begin
        rollback transaction
        raiserror (N'Sets inválidos!', 16, 1)
    end
end


insert into jogos
values
    (4, 1, 0, 3, 2)


