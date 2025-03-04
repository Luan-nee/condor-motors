-- Creación de tipos ENUM
CREATE TYPE tipo_local AS ENUM ('CENTRAL', 'local');
CREATE TYPE tipo_cliente AS ENUM ('NATURAL', 'JURIDICA');
CREATE TYPE rol_empleado AS ENUM ('ADMINISTRADOR', 'COLABORADOR', 'VENDEDOR', 'COMPUTADORA');
CREATE TYPE estado_venta AS ENUM ('PENDIENTE', 'CONFIRMADO', 'CANCELADO');
CREATE TYPE estado_movimiento AS ENUM ('SOLICITANDO', 'PREPARADO', 'RECIBIDO', 'APROBADO');
CREATE TYPE estado_detalle_movimiento AS ENUM ('PENDIENTE', 'RECIBIDO', 'INCOMPLETO');
CREATE TYPE tipo_comprobante AS ENUM ('BOLETA', 'FACTURA', 'NOTA_CREDITO', 'NOTA_DEBITO', 'GUIA_REMISION');

-- Tablas base
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL UNIQUE,
    descripcion VARCHAR(511)
);

CREATE TABLE marcas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL UNIQUE,
    descripcion VARCHAR(511)
);

CREATE TABLE locales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL UNIQUE,
    ubicacion VARCHAR(511),
    tipo tipo_local NOT NULL,
    telefono VARCHAR(20),
    activo BOOLEAN DEFAULT true,
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Tablas con dependencias
CREATE TABLE empleados (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_completo VARCHAR(255) NOT NULL,
    dni VARCHAR(10),
    rol rol_empleado NOT NULL,
    usuario VARCHAR(100) NOT NULL UNIQUE,
    clave VARCHAR(255) NOT NULL,
    fecha_pago DATE,
    fecha_contratacion DATE,
    activo BOOLEAN DEFAULT true,
    local_id INTEGER NOT NULL REFERENCES locales(id),
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    tipo tipo_cliente NOT NULL,
    nombres_apellidos VARCHAR(511),
    dni VARCHAR(8),
    razon_social VARCHAR(255),
    ruc VARCHAR(20),
    telefono VARCHAR(20),
    correo VARCHAR(255),
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE productos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(255) NOT NULL UNIQUE,
    nombre VARCHAR(255) NOT NULL,
    descripcion VARCHAR(255),
    precio_normal DECIMAL(10,2) NOT NULL,
    precio_compra DECIMAL(10,2) NOT NULL,
    precio_mayorista DECIMAL(10,2),
    precio_oferta DECIMAL(10,2),
    stock_minimo INTEGER DEFAULT 10,
    categoria_id INTEGER NOT NULL REFERENCES categorias(id),
    marca_id INTEGER NOT NULL REFERENCES marcas(id),
    imagen_url VARCHAR(1023),
    imagen_storage_path VARCHAR(1023),
    imagen_nombre VARCHAR(255),
    local_id INTEGER NOT NULL REFERENCES locales(id),
    fecha_ultima_venta TIMESTAMPTZ,
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Tablas de operaciones
CREATE TABLE stocks (
    id SERIAL PRIMARY KEY,
    producto_id INTEGER NOT NULL REFERENCES productos(id),
    local_id INTEGER NOT NULL REFERENCES locales(id),
    cantidad INTEGER NOT NULL DEFAULT 0,
    ultima_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(producto_id, local_id)
);

CREATE TABLE ventas (
    id SERIAL PRIMARY KEY,
    total DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(50) NOT NULL,
    estado estado_venta NOT NULL DEFAULT 'PENDIENTE',
    observaciones TEXT,
    tipo_comprobante tipo_comprobante NOT NULL DEFAULT 'BOLETA',
    serie_comprobante VARCHAR(4),
    numero_comprobante VARCHAR(8),
    fecha_comprobante TIMESTAMPTZ,
    guia_remision VARCHAR(20),
    orden_compra VARCHAR(20),
    condicion_pago VARCHAR(50),
    fecha_vencimiento DATE,
    subtotal DECIMAL(10,2) NOT NULL,
    igv DECIMAL(10,2) NOT NULL,
    descuento_total DECIMAL(10,2) DEFAULT 0,
    vendedor_id UUID REFERENCES empleados(id),
    computadora_id UUID REFERENCES empleados(id),
    cliente_id INTEGER REFERENCES clientes(id),
    local_id INTEGER NOT NULL REFERENCES locales(id),
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    fecha_confirmacion TIMESTAMPTZ,
    fecha_anulacion TIMESTAMPTZ,
    motivo_anulacion TEXT
);

CREATE TABLE detalles_venta (
    id SERIAL PRIMARY KEY,
    venta_id INTEGER NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
    producto_id INTEGER NOT NULL REFERENCES productos(id),
    cantidad INTEGER NOT NULL DEFAULT 1,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(10,2) NOT NULL,
    igv_unitario DECIMAL(10,2) NOT NULL,
    tipo_igv VARCHAR(2) DEFAULT '10',
    codigo_producto VARCHAR(255),
    descripcion_adicional TEXT
);

CREATE TABLE movimientos_stock (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES empleados(id),
    local_origen_id INTEGER NOT NULL REFERENCES locales(id),
    local_destino_id INTEGER NOT NULL REFERENCES locales(id),
    usuario_aprobador_id UUID REFERENCES empleados(id),
    estado estado_movimiento NOT NULL DEFAULT 'SOLICITANDO',
    fecha_movimiento TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    fecha_aprobacion TIMESTAMPTZ,
    observaciones TEXT
);

CREATE TABLE detalles_movimiento (
    id SERIAL PRIMARY KEY,
    movimiento_id INTEGER NOT NULL REFERENCES movimientos_stock(id) ON DELETE CASCADE,
    producto_id INTEGER NOT NULL REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    cantidad_recibida INTEGER,
    estado estado_detalle_movimiento NOT NULL DEFAULT 'PENDIENTE',
    observaciones TEXT
);

-- Índices
CREATE INDEX idx_productos_codigo ON productos(codigo);
CREATE INDEX idx_productos_nombre ON productos(nombre);
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_local ON productos(local_id);

CREATE INDEX idx_stocks_producto ON stocks(producto_id);
CREATE INDEX idx_stocks_local ON stocks(local_id);

CREATE INDEX idx_ventas_estado ON ventas(estado);
CREATE INDEX idx_ventas_fecha ON ventas(fecha_creacion);
CREATE INDEX idx_ventas_vendedor ON ventas(vendedor_id);
CREATE INDEX idx_ventas_local ON ventas(local_id);

CREATE INDEX idx_movimientos_estado ON movimientos_stock(estado);
CREATE INDEX idx_movimientos_fecha ON movimientos_stock(fecha_movimiento);
CREATE INDEX idx_movimientos_usuario ON movimientos_stock(usuario_id);

CREATE INDEX idx_ventas_comprobante ON ventas(tipo_comprobante, serie_comprobante, numero_comprobante);
CREATE INDEX idx_ventas_guia ON ventas(guia_remision);
CREATE INDEX idx_ventas_fecha_comprobante ON ventas(fecha_comprobante);

-- *************************************
-- SECCIÓN: DATOS INICIALES
-- *************************************

-- Insertar categorías
INSERT INTO categorias (nombre, descripcion) VALUES
('Motor y Transmisión', 'Componentes del motor y sistema de transmisión'),
('Frenos y Embrague', 'Sistema de frenos y embrague'),
('Suspensión y Dirección', 'Amortiguadores, horquillas y componentes de dirección'),
('Sistema Eléctrico', 'Baterías, luces y componentes eléctricos'),
('Carrocería y Chasis', 'Carenados, asientos y partes del chasis'),
('Llantas y Ruedas', 'Neumáticos, aros y relacionados'),
('Aceites y Fluidos', 'Lubricantes, líquido de frenos y refrigerantes'),
('Accesorios', 'Cascos, guantes, alforjas y otros accesorios');

-- Insertar marcas
INSERT INTO marcas (nombre, descripcion) VALUES
('Honda Motos', 'Repuestos originales Honda Motorcycles'),
('Yamaha', 'Repuestos originales Yamaha'),
('Bajaj', 'Repuestos originales Bajaj'),
('Suzuki', 'Repuestos originales Suzuki'),
('Kawasaki', 'Repuestos originales Kawasaki'),
('TVS', 'Repuestos originales TVS'),
('Zongshen', 'Repuestos originales Zongshen'),
('Genérico', 'Repuestos alternativos de calidad');

-- Insertar locales
INSERT INTO locales (nombre, ubicacion, tipo, telefono) VALUES
('Central Lima', 'Av. Principal 123, Lima', 'CENTRAL', '01-234-5678'),
('Sucursal Norte', 'Av. Norte 456, Los Olivos', 'SUCURSAL', '01-345-6789'),
('Sucursal Sur', 'Av. Sur 789, San Juan', 'SUCURSAL', '01-456-7890');

-- Insertar empleados (clave: "password123" para todos en este ejemplo)
INSERT INTO empleados (id, nombre_completo, dni, rol, usuario, clave, fecha_contratacion, local_id) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'Admin Principal', '12345678', 'ADMINISTRADOR', 'admin', '123', '2024-01-01', 1),
('550e8400-e29b-41d4-a716-446655440001', 'Juan Pérez', '87654321', 'COLABORADOR', 'colab', '123', '2024-01-01', 1),
('550e8400-e29b-41d4-a716-446655440002', 'María García', '11223344', 'VENDEDOR', 'vendor', '123', '2024-01-01', 2),
('550e8400-e29b-41d4-a716-446655440003', 'PC Central', '00000001', 'COMPUTADORA', 'pc', '123', '2024-01-01', 1);

-- Insertar productos
INSERT INTO productos (codigo, nombre, descripcion, precio_normal, precio_compra, precio_mayorista, categoria_id, marca_id, local_id, stock_minimo) VALUES
('HON-001', 'Kit de Arrastre Honda CG150', 'Kit completo de arrastre para Honda CG150', 180.00, 120.00, 150.00, 1, 1, 1, 5),
('YAM-001', 'Pastillas de Freno Yamaha FZ', 'Juego de pastillas de freno delanteras', 45.00, 25.00, 35.00, 2, 2, 1, 10),
('BAJ-001', 'Kit de Empaques Bajaj Pulsar', 'Kit completo de empaques para motor', 85.00, 55.00, 70.00, 1, 3, 1, 5),
('SUZ-001', 'Amortiguador Suzuki GN125', 'Par de amortiguadores traseros', 220.00, 150.00, 180.00, 3, 4, 1, 4),
('KAW-001', 'Batería Kawasaki Ninja', 'Batería sellada 12V', 280.00, 180.00, 230.00, 4, 5, 1, 3),
('ACC-001', 'Casco Integral DOT', 'Casco certificado talla M', 250.00, 150.00, 200.00, 8, 8, 1, 5),
('ACE-001', 'Aceite Motul 5100 4T', 'Aceite sintético 10W40 1L', 45.00, 30.00, 38.00, 7, 8, 1, 15);

-- Insertar stocks iniciales
INSERT INTO stocks (producto_id, local_id, cantidad) VALUES
(1, 1, 15),
(2, 1, 20),
(3, 1, 12),
(4, 1, 8),
(5, 1, 10),
(6, 1, 15),
(7, 1, 24);

-- Insertar clientes de ejemplo
INSERT INTO clientes (tipo, nombres_apellidos, dni, razon_social, ruc, telefono, correo) VALUES
('NATURAL', 'Pedro Sánchez', '44556677', NULL, NULL, '999888777', 'pedro@email.com'),
('JURIDICA', NULL, NULL, 'Talleres Unidos S.A.C.', '20123456789', '998877665', 'contacto@talleres.com');

-- Crear políticas de storage
-- Ejecutar esto en el SQL Editor de Supabase:

-- Crear bucket para imágenes de productos
INSERT INTO storage.buckets (id, name, public) VALUES 
('productos', 'productos', true);

-- Política para ver imágenes (público)
CREATE POLICY "Imágenes públicas"
ON storage.objects FOR SELECT
USING (bucket_id = 'productos');

-- Política para subir imágenes (solo admin y colaborador)
CREATE POLICY "Subida de imágenes por admin y colaborador"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'productos' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM empleados 
        WHERE id = auth.uid()::uuid 
        AND rol IN ('ADMINISTRADOR', 'COLABORADOR')
    )
);

-- Política para actualizar imágenes (solo admin y colaborador)
CREATE POLICY "Actualización de imágenes por admin y colaborador"
ON storage.objects FOR UPDATE
USING (
    bucket_id = 'productos' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM empleados 
        WHERE id = auth.uid()::uuid 
        AND rol IN ('ADMINISTRADOR', 'COLABORADOR')
    )
);

-- Política para eliminar imágenes (solo administradores)
CREATE POLICY "Eliminación de imágenes por admin"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'productos' 
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM empleados 
        WHERE id = auth.uid()::uuid 
        AND rol = 'ADMINISTRADOR'
    )
);

-- Ejemplo de inserción con datos de comprobante
INSERT INTO ventas (
    total, 
    subtotal,
    igv,
    metodo_pago,
    tipo_comprobante,
    serie_comprobante,
    numero_comprobante,
    fecha_comprobante,
    guia_remision,
    vendedor_id,
    cliente_id,
    local_id
) VALUES (
    118.00,
    100.00,
    18.00,
    'EFECTIVO',
    'BOLETA',
    'B001',
    '00000001',
    CURRENT_TIMESTAMP,
    'T001-00000001',
    '550e8400-e29b-41d4-a716-446655440000',
    1,
    1
);

-- *************************************
-- SECCIÓN: FUNCIONES
-- *************************************

-- Función para obtener el stock de un producto en un local específico
CREATE OR REPLACE FUNCTION get_stock_by_local(p_local_id INTEGER)
RETURNS TABLE (
    stock_id INTEGER,
    producto_id INTEGER,2
    nombre VARCHAR(255),
    cantidad INTEGER,
    precio_normal DECIMAL(10,2),
    precio_mayorista DECIMAL(10,2),
    categoria_id INTEGER,
    marca_id INTEGER,
    stock_minimo INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as stock_id,
        p.id as producto_id,
        p.codigo,
        p.nombre,
        s.cantidad,
        p.precio_normal,
        p.precio_mayorista,
        p.categoria_id,
        p.marca_id,
        p.stock_minimo
    FROM stocks s
    INNER JOIN productos p ON p.id = s.producto_id
    WHERE s.local_id = p_local_id
    ORDER BY p.nombre;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener productos con stock bajo en un local
CREATE OR REPLACE FUNCTION get_low_stock_products(p_local_id INTEGER)
RETURNS TABLE (
    stock_id INTEGER,
    producto_id INTEGER,
    codigo VARCHAR(255),
    nombre VARCHAR(255),
    cantidad INTEGER,
    stock_minimo INTEGER,
    categoria_nombre VARCHAR(255),
    marca_nombre VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.id as stock_id,
        p.id as producto_id,
        p.codigo,
        p.nombre,
        s.cantidad,
        p.stock_minimo,
        c.nombre as categoria_nombre,
        m.nombre as marca_nombre
    FROM stocks s
    INNER JOIN productos p ON p.id = s.producto_id
    INNER JOIN categorias c ON c.id = p.categoria_id
    INNER JOIN marcas m ON m.id = p.marca_id
    WHERE s.local_id = p_local_id
    AND s.cantidad <= p.stock_minimo
    ORDER BY s.cantidad ASC;
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar el stock de un producto
CREATE OR REPLACE FUNCTION update_stock(
    p_producto_id INTEGER,
    p_local_id INTEGER,
    p_cantidad INTEGER,
    p_tipo_operacion VARCHAR(1) -- 'A' para agregar, 'R' para restar
)
RETURNS INTEGER AS $$
DECLARE
    v_stock_actual INTEGER;
    v_nuevo_stock INTEGER;
BEGIN
    -- Obtener stock actual
    SELECT cantidad INTO v_stock_actual
    FROM stocks
    WHERE producto_id = p_producto_id AND local_id = p_local_id;

    -- Calcular nuevo stock
    IF p_tipo_operacion = 'A' THEN
        v_nuevo_stock := v_stock_actual + p_cantidad;
    ELSIF p_tipo_operacion = 'R' THEN
        v_nuevo_stock := v_stock_actual - p_cantidad;
        -- Validar que no quede negativo
        IF v_nuevo_stock < 0 THEN
            RAISE EXCEPTION 'Stock insuficiente';
        END IF;
    ELSE
        RAISE EXCEPTION 'Operación no válida';
    END IF;

    -- Actualizar stock
    UPDATE stocks
    SET 
        cantidad = v_nuevo_stock,
        ultima_actualizacion = CURRENT_TIMESTAMP
    WHERE producto_id = p_producto_id AND local_id = p_local_id;

    RETURN v_nuevo_stock;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar disponibilidad de stock
CREATE OR REPLACE FUNCTION check_stock_availability(
    p_producto_id INTEGER,
    p_local_id INTEGER,
    p_cantidad INTEGER
)
RETURNS BOOLEAN AS $$
DECLARE
    v_stock_actual INTEGER;
BEGIN
    SELECT cantidad INTO v_stock_actual
    FROM stocks
    WHERE producto_id = p_producto_id AND local_id = p_local_id;

    RETURN v_stock_actual >= p_cantidad;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener el historial de movimientos de un producto
CREATE OR REPLACE FUNCTION get_producto_movimientos(
    p_producto_id INTEGER,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE (
    fecha_movimiento TIMESTAMPTZ,
    tipo_movimiento VARCHAR(50),
    cantidad INTEGER,
    local_origen VARCHAR(255),
    local_destino VARCHAR(255),
    estado VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ms.fecha_movimiento,
        'MOVIMIENTO' as tipo_movimiento,
        dm.cantidad,
        lo.nombre as local_origen,
        ld.nombre as local_destino,
        ms.estado::VARCHAR
    FROM movimientos_stock ms
    INNER JOIN detalles_movimiento dm ON dm.movimiento_id = ms.id
    INNER JOIN locales lo ON lo.id = ms.local_origen_id
    INNER JOIN locales ld ON ld.id = ms.local_destino_id
    WHERE dm.producto_id = p_producto_id
    AND ms.fecha_movimiento BETWEEN p_fecha_inicio AND p_fecha_fin
    ORDER BY ms.fecha_movimiento DESC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener ventas por período
CREATE OR REPLACE FUNCTION get_ventas_por_periodo(
    p_fecha_inicio DATE,
    p_fecha_fin DATE,
    p_local_id INTEGER DEFAULT NULL
)
RETURNS TABLE (
    fecha DATE,
    total_ventas DECIMAL(10,2),
    cantidad_ventas BIGINT,
    promedio_venta DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(v.fecha_creacion) as fecha,
        SUM(v.total) as total_ventas,
        COUNT(*) as cantidad_ventas,
        AVG(v.total) as promedio_venta
    FROM ventas v
    WHERE v.fecha_creacion::DATE BETWEEN p_fecha_inicio AND p_fecha_fin
    AND (p_local_id IS NULL OR v.local_id = p_local_id)
    AND v.estado = 'CONFIRMADO'
    GROUP BY DATE(v.fecha_creacion)
    ORDER BY fecha;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener productos más vendidos
CREATE OR REPLACE FUNCTION get_productos_mas_vendidos(
    p_fecha_inicio DATE,
    p_fecha_fin DATE,
    p_local_id INTEGER DEFAULT NULL,
    p_limite INTEGER DEFAULT 10
)
RETURNS TABLE (
    producto_id INTEGER,
    codigo VARCHAR(255),
    nombre VARCHAR(255),
    cantidad_vendida BIGINT,
    total_ventas DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as producto_id,
        p.codigo,
        p.nombre,
        SUM(dv.cantidad) as cantidad_vendida,
        SUM(dv.subtotal) as total_ventas
    FROM detalles_venta dv
    INNER JOIN ventas v ON v.id = dv.venta_id
    INNER JOIN productos p ON p.id = dv.producto_id
    WHERE v.fecha_creacion::DATE BETWEEN p_fecha_inicio AND p_fecha_fin
    AND v.estado = 'CONFIRMADO'
    AND (p_local_id IS NULL OR v.local_id = p_local_id)
    GROUP BY p.id, p.codigo, p.nombre
    ORDER BY cantidad_vendida DESC
    LIMIT p_limite;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener el dashboard de ventas
CREATE OR REPLACE FUNCTION get_dashboard_ventas(
    p_local_id INTEGER,
    p_fecha DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    ventas_hoy DECIMAL(10,2),
    ventas_mes DECIMAL(10,2),
    cantidad_ventas_hoy BIGINT,
    cantidad_ventas_mes BIGINT,
    promedio_venta_hoy DECIMAL(10,2),
    promedio_venta_mes DECIMAL(10,2),
    productos_sin_stock BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH metricas_ventas AS (
        SELECT
            SUM(CASE WHEN DATE(fecha_creacion) = p_fecha THEN total ELSE 0 END) as ventas_hoy,
            SUM(CASE WHEN DATE_TRUNC('month', fecha_creacion) = DATE_TRUNC('month', p_fecha::TIMESTAMP) THEN total ELSE 0 END) as ventas_mes,
            COUNT(CASE WHEN DATE(fecha_creacion) = p_fecha THEN 1 END) as cant_ventas_hoy,
            COUNT(CASE WHEN DATE_TRUNC('month', fecha_creacion) = DATE_TRUNC('month', p_fecha::TIMESTAMP) THEN 1 END) as cant_ventas_mes
        FROM ventas
        WHERE local_id = p_local_id
        AND estado = 'CONFIRMADO'
    ),
    productos_agotados AS (
        SELECT COUNT(*) as sin_stock
        FROM stocks
        WHERE local_id = p_local_id
        AND cantidad = 0
    )
    SELECT
        mv.ventas_hoy,
        mv.ventas_mes,
        mv.cant_ventas_hoy,
        mv.cant_ventas_mes,
        CASE WHEN mv.cant_ventas_hoy > 0 THEN mv.ventas_hoy / mv.cant_ventas_hoy ELSE 0 END,
        CASE WHEN mv.cant_ventas_mes > 0 THEN mv.ventas_mes / mv.cant_ventas_mes ELSE 0 END,
        pa.sin_stock
    FROM metricas_ventas mv
    CROSS JOIN productos_agotados pa;
END;
$$ LANGUAGE plpgsql;

-- Triggers para mantener la integridad de los stocks

-- Trigger para actualizar stock después de una venta
CREATE OR REPLACE FUNCTION update_stock_after_venta()
RETURNS TRIGGER AS $$
BEGIN
    -- Si la venta es confirmada, restar del stock
    IF NEW.estado = 'CONFIRMADO' AND (OLD.estado IS NULL OR OLD.estado != 'CONFIRMADO') THEN
        UPDATE stocks s
        SET cantidad = s.cantidad - dv.cantidad
        FROM detalles_venta dv
        WHERE dv.venta_id = NEW.id
        AND s.producto_id = dv.producto_id
        AND s.local_id = NEW.local_id;
    -- Si la venta es anulada, devolver al stock
    ELSIF NEW.estado = 'CANCELADO' AND OLD.estado = 'CONFIRMADO' THEN
        UPDATE stocks s
        SET cantidad = s.cantidad + dv.cantidad
        FROM detalles_venta dv
        WHERE dv.venta_id = NEW.id
        AND s.producto_id = dv.producto_id
        AND s.local_id = NEW.local_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_after_venta
AFTER UPDATE OF estado ON ventas
FOR EACH ROW
EXECUTE FUNCTION update_stock_after_venta();

-- Trigger para actualizar stock después de un movimiento
CREATE OR REPLACE FUNCTION update_stock_after_movimiento()
RETURNS TRIGGER AS $$
BEGIN
    -- Si el movimiento es aprobado
    IF NEW.estado = 'APROBADO' AND OLD.estado != 'APROBADO' THEN
        -- Restar del stock origen
        UPDATE stocks s
        SET cantidad = s.cantidad - dm.cantidad
        FROM detalles_movimiento dm
        WHERE dm.movimiento_id = NEW.id
        AND s.producto_id = dm.producto_id
        AND s.local_id = NEW.local_origen_id;
        
        -- Sumar al stock destino
        UPDATE stocks s
        SET cantidad = s.cantidad + dm.cantidad_recibida
        FROM detalles_movimiento dm
        WHERE dm.movimiento_id = NEW.id
        AND s.producto_id = dm.producto_id
        AND s.local_id = NEW.local_destino_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_stock_after_movimiento
AFTER UPDATE OF estado ON movimientos_stock
FOR EACH ROW
EXECUTE FUNCTION update_stock_after_movimiento();