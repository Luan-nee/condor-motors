# Query: `stock`

nombre: stock
valor: [value],[filterType]

## Explicación del `valor`

### value

Es el valor que se utilizará para comparar con el stock del producto
Solo se aceptan valores numéricos, en caso de que el valor no sea un número la query se ignorará y no se aplicará el filtro sobre los resultados

### filterType

Es el tipo de filtro a aplicar, solo puede ser uno de los siguientes valores:

- "eq": Para obtener solo aquellos productos que tienen un stock igual a `value`
- "gte": Para obtener solo aquellos productos que tienen un stock mayor o igual a `value`
- "lte": Para obtener solo aquellos productos que tienen un stock menor o igual a `value`
- "ne": Para obtener solo aquellos productos que tienen un stock diferente a `value`

Notas:
En caso de no proporcionar un valor para `filterType` se utilizará el filtro `eq` por defecto

## Ejemplos de Uso de la Query `stock`

La query `stock` permite filtrar los productos según su cantidad en inventario. A continuación, se presentan ejemplos de cómo utilizar esta query y su efecto en los resultados:

### Ejemplo 1: Filtrar productos con stock igual a un valor específico

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=10,eq
```

**Descripción:**
Obtiene los productos cuyo stock es exactamente igual a `10`.

---

### Ejemplo 2: Filtrar productos con stock mayor o igual a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=5,gte
```

**Descripción:**
Obtiene los productos cuyo stock es mayor o igual a `5`.

---

### Ejemplo 3: Filtrar productos con stock menor o igual a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=20,lte
```

**Descripción:**
Obtiene los productos cuyo stock es menor o igual a `20`.

---

### Ejemplo 4: Filtrar productos con stock diferente a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=15,ne
```

**Descripción:**
Obtiene los productos cuyo stock es diferente a `15`.

---

### Ejemplo 5: Uso del filtro por defecto (`eq`)

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=8
```

**Descripción:**
Si no se especifica un `filterType`, se utiliza el filtro `eq` por defecto. En este caso, se obtendrán los productos cuyo stock es igual a `8`.

---

### Notas Adicionales

- Si el valor proporcionado para `value` no es un número, la query será ignorada y no se aplicará ningún filtro.
- Asegúrese de que el valor de `filterType` sea uno de los permitidos: `eq`, `gte`, `lte`, `ne`. De lo contrario, se aplicará el filtro `eq` por defecto.
- Estas queries pueden combinarse con otros parámetros para realizar búsquedas más específicas.
