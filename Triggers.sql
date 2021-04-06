create database FuncTrigger
go
use FuncTrigger

create table Produto(
codigo int,
nome varchar(50),
descricao varchar(250),
valor_unitario decimal(5,2)
primary key(codigo))

insert into Produto values
(1,'Produto 1','desc',10.0),
(2,'Produto 2','desc',20.0),
(3,'Produto 3','desc',30.0)


create table Estoque(
codigo int,
codigo_produto int,
qnt_estoque int,
estoque_minimo int
primary key(codigo),
foreign key(codigo_produto) references Produto(codigo))

insert into Estoque values
(1,1,10,10),
(2,2,20,10),
(3,3,9,10)

create table Venda(
nota_fiscal int,
codigo_produto int,
quantidade int,
primary key(nota_fiscal),
foreign key(codigo_produto) references Produto(codigo))

insert into Venda values
(100,1,1)
insert into Venda values
(200,2,2)
insert into Venda values
(300,3,1)


CREATE TRIGGER t_vendas ON Venda
AFTER INSERT
AS
BEGIN
	declare @qnt_nova_venda as int, @qnt_estoque int, @qnt_estoque_minimo int,@cod_produto int
	set @cod_produto = (SELECT codigo_produto from INSERTED)
	SET @qnt_nova_venda = (SELECT quantidade FROM INSERTED)
	set @qnt_estoque = (SELECT qnt_estoque from Estoque where codigo_produto = @cod_produto)
	set @qnt_estoque_minimo = (SELECT estoque_minimo from Estoque where codigo_produto = @cod_produto)
	
	IF @qnt_nova_venda < @qnt_estoque
	BEGIN
		if @qnt_estoque_minimo > @qnt_estoque
		BEGIN
			print 'Estoque abaixo do valor mínimo'
		END
		ELSE
		BEGIN
			if @qnt_estoque_minimo > (@qnt_estoque - @qnt_nova_venda)
			BEGIN
				print 'Estoque ficará abaixo do valor mínimo após a venda'
			END
		END
	END
	ELSE
	BEGIN
		ROLLBACK TRANSACTION
		RAISERROR('Quantidade de produtos na venda superior ao do estoque', 16, 1)
	END
END

CREATE FUNCTION fn_vendas(@nota_fiscal int)
RETURNS @table TABLE (
nota_fiscal int,
codigo_produto int,
nome_produto varchar(50),
descricao_produto varchar(150),
valor_unitario decimal(5,2),
quantidade int,
valor_total decimal(5,2))
as
begin
	insert into @table (nota_fiscal,codigo_produto,nome_produto,descricao_produto,valor_unitario,quantidade) 
					select v.nota_fiscal,v.codigo_produto,p.nome,p.descricao,p.valor_unitario,v.quantidade FROM Venda v, Produto p where v.codigo_produto = p.codigo and v.nota_fiscal = @nota_fiscal	
	update @table set valor_total = (quantidade * valor_unitario)
	return 
end

SELECT * from dbo.fn_vendas(300)