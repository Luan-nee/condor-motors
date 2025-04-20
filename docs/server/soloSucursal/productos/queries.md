# Query: `stock`

- **Nombre:** `stock`
- **Valor:** `[value],[filterType]`

## Estructura del parámetro `stock`

La query `stock` permite filtrar productos según su cantidad disponible en inventario. A continuación se explica cómo utilizarla correctamente.

### `value`

Corresponde al valor numérico que se utilizará para comparar contra el stock del producto.

- Solo se aceptan valores numéricos.
- Si el valor no es un número válido, el filtro será ignorado y no afectará los resultados.

### `filterType`

Define el tipo de comparación a realizar. Los valores permitidos son:

| Valor | Descripción             |
| ----- | ----------------------- |
| `eq`  | Igual a `value`         |
| `gte` | Mayor o igual a `value` |
| `lte` | Menor o igual a `value` |
| `ne`  | Diferente a `value`     |

> **Nota:** Si no se especifica `filterType`, se aplicará `eq` de forma predeterminada.

---

## Ejemplos de uso

### 1. Filtrar productos con stock **igual** a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=10,eq
```

**Descripción:**  
Devuelve los productos cuyo stock es exactamente igual a `10`.

---

### 2. Filtrar productos con stock **mayor o igual** a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=5,gte
```

**Descripción:**  
Devuelve los productos cuyo stock es mayor o igual a `5`.

---

### 3. Filtrar productos con stock **menor o igual** a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=20,lte
```

**Descripción:**  
Devuelve los productos cuyo stock es menor o igual a `20`.

---

### 4. Filtrar productos con stock **diferente** a un valor

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=15,ne
```

**Descripción:**  
Devuelve los productos cuyo stock es diferente a `15`.

---

### 5. Uso del filtro por defecto (`eq`)

**Query:**

```url
{{base_url}}/api/{{idSucursal}}/productos?stock=8
```

**Descripción:**  
Si no se especifica el tipo de filtro, se aplicará `eq` por defecto. En este caso, se devolverán los productos con stock igual a `8`.

---

## Consideraciones adicionales

- Si `value` no es un número válido, el filtro no se aplicará.
- Si `filterType` no está presente o es inválido, se usará `eq` como filtro predeterminado.
- Esta query puede combinarse con otros parámetros para realizar búsquedas más complejas y específicas.
