<%@ page contentType="text/html; charset=UTF-8" isELIgnored="false" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <title>Bienvenido - My Construction</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/styles.css" />
</head>
<body>
  <div class="card">
    <h1>Bienvenido a My Construction</h1>

    <c:if test="${param.login == 'ok'}">
      <div class="success">Ingreso exitoso.</div>
    </c:if>

    <p>Este es el inicio del sistema.</p>
    <a href="${pageContext.request.contextPath}/login.jsp">Cerrar sesión</a>
  </div>
</body>
</html>
