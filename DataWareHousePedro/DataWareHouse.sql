create database DataWareHouseExportacao
go

use DataWareHouseExportacao
go


--arquivo utilizado na importa��o de dados 'Exportac�o Data WareHouse - CAF�.xls'
alter table Exportacao
add CodigoExportacao int primary key identity(1,1) 
go

Select * From Exportacao
Go

-- Criando a Dimens�o Tempo - DimTime (when)
Create Table DimTempo
(CodigoTempo Int Identity(1,1) Not Null,
 CodigoExportacao int not null,
 Mes TinyInt Not Null,
 MesPorExtenso Varchar(15) Not Null,
 Quartil TinyInt Not Null,
 QuartilPorExtenso Varchar(20) Not Null,
 Ano Int Not Null,
 AnoPorExtenso Varchar(40) Not Null
 Constraint [PK_DimTime_TimeID] Primary Key Clustered (CodigoTempo))
Go




--what -- Where - referente ao SH4 901(Caf�)
create table DimProduto
(CodigoProduto int identity(1,1) primary key,
CodigoExportacao int not null,
NomeProduto varchar(10) not null,
NumeroIdentificacaoSH4 int default 901, --CO_SH4
EstadoOrigem varchar(5) not null, -- CO_UF
DataCadastro DateTime Default GetDate(),
AnoCadastro As Year(DataCadastro),
MesCadastro As Month(DataCadastro),
DiaCadastro As Day(DataCadastro)
)
go



--Who  -- why  - Por que outro pais(Who) comprou nosso produto (CO_PAIS)
Create table DimVendas
(CodigoVendas int identity(1,1) primary key,
CodigoPais int not null, --(CO_PAIS)
CodigoProduto int not null,
CodigoTempo int not null,
CodigoExportacao int not null,
NomePais varchar(60) not null,
UF varchar(2) not null,
KG int,
ValorFOB float
)
go




--criando a tabela fato
Create table FatoExportacao
(CodigoFatoExportacao int not null primary key identity(1,1),
CodigoExportacao int not null,
CodigoProduto int not null,
CodigoTempo int not null,
CodigoVendas int not null,
MetricaValorFOB float, --valor em R$
MetricaKG int,
MetricaValorTranportePorKG as (MetricaValorFOB / MetricaKG) --Valor Em R$
)
go




-- Populando as tabelas com base na Tabela Exportaca --

--Populando a DimTempo
Insert Into DimTempo ([Mes], [MesPorExtenso], [Quartil], [QuartilPorExtenso], [Ano], [AnoPorExtenso] , [CodigoExportacao])
Select Mes As Mes,
	   Case Mes 
	    When 1 Then 'Janeiro'
		When 2 Then 'Fevereiro'
		When 3 Then 'Mar�o'
		When 4 Then 'Abril'
		When 5 Then 'Maio'
		When 6 Then 'Junho'
		When 7 Then 'Julho'
		When 8 Then 'Agosto'
		When 9 Then 'Setembro'
		When 10 Then 'Outubro'
		When 11 Then 'Novembro'
		When 12 Then 'Dezembro'
	   End As MesPorExtenso,
	   Case 
	    When Mes = 1 Then 1
		When Mes = 2 Then 1
		When Mes = 3 Then 1
		When Mes = 4 Then 2
		When Mes = 5 Then 2
		When Mes = 6 Then 2
		When Mes = 7 Then 3
		When Mes = 8 Then 3
		When Mes = 9 Then 3
		When Mes = 10 Then 4
		When Mes = 11 Then 4
		When Mes = 12 Then 4
	   End As Quartil,
	   Case 
	    When (Mes >=1) And (Mes <=3) Then 'Primeiro Quartil'
		When (Mes >=4) And (Mes <=6) Then 'Segundo Quartil'
		When (Mes >=7) And (Mes <=9) Then 'Terceiro Quartil'
		When (Mes >=10) Then 'Quarto Quartil'
	   End As QuartilPorExtenso,
	   Ano As Ano,
	   case
	   when Ano = 1997 then 'mil novecentos e noventa e sete'
	   when Ano = 1998 then 'mil novecentos e noventa e oito'
	   when Ano = 1999 then 'mil novecentos e noventa e nove'
	   End as AnoPorExtenso,
	   CodigoExportacao as CodigoExportacao
From Exportacao
Go

--consultando o insert
select * from DimTempo
go





--Populando a DimProduto
insert into DimProduto ([CodigoExportacao] , [NomeProduto] , [EstadoOrigem])
select CodigoExportacao as CodigoExportacao,
	   Produto as NomeProduto,
	   UF as EstadoOrigem
from Exportacao
go

--consultando o insert
select * from DimProduto
go




--populando a DimVendas
insert into DimVendas ([CodigoPais] , [CodigoExportacao] , [NomePais] , [UF] , [KG] , [ValorFOB] , [CodigoProduto] , [CodigoTempo])
select EX.CodigoPais as CodigoPais,
	   EX.CodigoExportacao as CodigoExportacao,
	   EX.NomePais as NomePais,
	   EX.UF as UF,
	   EX.KG as KG,
	   EX.Valor as ValorFOB,
	   DP.CodigoProduto as CodigoProduto,
	   DT.CodigoTempo as CodigoTempo
from Exportacao EX inner join DimProduto DP
						on EX.CodigoExportacao = DP.CodigoExportacao
						inner join DimTempo DT
								on EX.CodigoExportacao = DT.CodigoExportacao
go


--consultando os inserts
select * from DimVendas
go




--Populando a tabela FatoExportacao
insert into FatoExportacao ([CodigoExportacao] , [CodigoProduto] , [CodigoTempo] , [CodigoVendas], [MetricaValorFOB] , [MetricaKG])
select 
		EX.CodigoExportacao as CodigoExportacao,
		DP.CodigoProduto as CodigoProduto,
		DT.CodigoTempo as CodigoTempo, 
		DV.CodigoVendas as CodigoVendas,
		EX.Valor as MetricaValorFOB,
		EX.KG as MetricaKG

from Exportacao EX inner join DimProduto DP
						on EX.CodigoExportacao = DP.CodigoExportacao
							inner join DimTempo DT
								on EX.CodigoExportacao = DT.CodigoExportacao
									inner join DimVendas DV
										on Ex.CodigoExportacao = DV.CodigoExportacao
go

--consultando os inserts
select * from FatoExportacao
go



--iniciando os relacionamentos
--DimTempo
alter table DimTempo
add constraint FK_CodigoExportacao_Exportacao_DimTempo foreign key (CodigoExportacao)
references Exportacao(CodigoExportacao)
go


--dimProduto
alter table DimProduto
add constraint FK_CodigoExportacao_Exportacao_DimProduto foreign key (CodigoExportacao)
references Exportacao(CodigoExportacao)
go


--DimVendas
alter table DimVendas
add constraint FK_CodigoExportacao_Exportacao_DimVendas foreign key (CodigoExportacao)
references Exportacao(CodigoExportacao)
go

alter table DimVendas
add constraint FK_CodigoProduto_Produto foreign key (CodigoProduto)
references DimProduto(CodigoProduto)
go

alter table DimVendas
add constraint FK_CodigoTempo_Tempo foreign key (CodigoTempo)
references DimTempo(CodigoTempo)
go


--FatoExportacao

alter table FatoExportacao
add constraint FK_CodigoExportacao_Exportacao_FatoExportacao foreign key (CodigoExportacao)
references Exportacao(CodigoExportacao)
go

alter table FatoExportacao
add constraint FK_CodigoProduto_Produto_FatoExportacao foreign key (CodigoProduto)
references DimProduto(CodigoProduto)
go

alter table FatoExportacao
add constraint FK_CodigoTempo_Tempo_FatoExportacao foreign key (CodigoTempo)
references DimTempo(CodigoTempo)
go

alter table FatoExportacao
add constraint FK_CodigoVendas_DimVendaS_FatoExportacao foreign key (CodigoVendas)
references DimVEndas(CodigoVendas)
go





--Select na tabela fato 
--utilizando inner join com as outras tabelas para que n�o apare�a apenas n�meros no select, dificultando o entendimento
Select FEX.CodigoExportacao , DP.NomeProduto , DP.NumeroIdentificacaoSH4,  DV.UF as 'Estado de Origem' , DV.KG, DV.ValorFOB, FEX.MetricaValorTranportePorKG, DV.NomePais as 'Pais para qual o produto foi exportado',
				DT.Mes, DT.MesPorExtenso, DT.Quartil, DT.QuartilPorExtenso, DT.Ano, DT.AnoPorExtenso

from FatoExportacao FEX inner join DimProduto DP
						on FEX.CodigoExportacao = DP.CodigoExportacao
							inner join DimTempo DT
								on FEX.CodigoExportacao = DT.CodigoExportacao
									inner join DimVendas DV
										on FEX.CodigoExportacao = DV.CodigoExportacao
go







/*
--comando para fazer o backup completo, assim trazendo as tabelas j� criadas anteriormente no script
alter database DataWareHouseExportacao
Set Recovery full 
Go

backup database DataWareHouseExportacao
to disk = 'C:\MeuBanco\Backup-Database-DataWareHouseExportacao.bak'
with init,
Description = 'Backup do banco de dados DataWareHouseExportacao',
stats= 5
go

backup log DataWareHouseExportacao
to disk = 'C:\MeuBanco\Backup-log-DataWareHouseExportacao.trn'
with init,
Description = 'Backup do arquivo de log',
ExpireDate = '30-12-2022',
stats = 5
go
*/