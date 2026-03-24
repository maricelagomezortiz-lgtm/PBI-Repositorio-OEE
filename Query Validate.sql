
--Query Valida Consulta que se vincula a Power BI

select ot.fecha,ot.id_orden, op.secuencia,ct.nombre as ct,art.nombre as np, art.tipo,
rep.cantidad_producida,(rep.tiempo_real_horas / op.tiempo_std_pza) as qstrd, rep.piezas_malas,rep.causa_scrap,
rep.tiempo_real_horas, (rep.cantidad_producida * op.tiempo_std_pza) as tstd,rep.tiempo_muerto_horas, causa_tiempo_muerto

from 
reporte_tiempos rep
left join ordenes_produccion ot on rep.id_orden = ot.id_orden
left join operaciones op on rep.id_operacion = op.id_operacion
left join centros_trabajo ct on op.id_centro = ct.id_centro
left join rutas on op.id_ruta = rutas.id_ruta
left join articulos art on rutas.id_articulo = art.id_articulo
order by 1,2



