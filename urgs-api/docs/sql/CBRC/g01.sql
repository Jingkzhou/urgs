insert into a_repot_val (index_num,index_name,index_val,report_num)  
select 'G01_5..B','5.应收利息.外币折人民币', t.loan_bal,'G01' from smtmods.l_acct_loan  t ;
insert into a_repot_val (index_num,index_name,index_val,report_num)  
select 'G01_41..C','41.其他应付款.本外币合计', t.loan_bal,'G01' from smtmods.l_acct_loan  t ;
