<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
  <title>Login - My Construction</title>
  <link rel="stylesheet" href="assets/css/styles.css"/>
</head>
<body>
  <div class="center">
    <div class="card">
      <h2>Acceso a My Construction</h2>
      <p>Ingrese sus credenciales</p>
      <c:if test="${param.error == '1'}">
        <div class="alert">Usuario o contraseña incorrectos</div>
      </c:if>
      <form action="login" method="post">
        <input class="input" type="text" name="usuario" placeholder="Usuario" required />
        <input class="input" type="password" name="clave" placeholder="Contraseña" required />
        <button class="btn btn-primary" type="submit">Ingresar</button>
      </form>
    </div>
  </div>
</body>
</html>
