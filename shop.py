#!/usr/bin/python
# -*- coding: utf-8 -*-
from __future__ import unicode_literals
from django.shortcuts import render, HttpResponse, HttpResponseRedirect
from django.core.urlresolvers import reverse
from inventario.models import Produto, Categoria, Linha
from .forms import EntregaForm
from .models import Logradouro, Cidade, Bairro, Entrega, Pedido, PedidoItem
import json
from django.contrib.auth.decorators import login_required

import datetime
# Create your views here.


def home(request):

    categorias = Categoria.objects.all()
    linhas = Linha.objects.all()

    return render(request, 'shop/home.html', {'categorias': categorias, 'linhas': linhas})


def add_to_cart(request, prod_id, qtd):

    cart = request.session.get('cart', {})
    cart[prod_id] = qtd
    preco_total = 0
    for key, value in cart.items():
        cart[key] = int(cart[key])
        if cart[key] == 0:
            cart.pop(key, None)
    for key, value in cart.items():
        p = Produto.objects.get(pk=key).preco
        q = value
        sub_tot = p*q
        preco_total += sub_tot
    n_items = sum(cart.values())
    request.session['cart'] = cart
    request.session['preco_total'] = float(preco_total)
    request.session['n_items'] = n_items
    response = json.dumps({"total": float(preco_total), "n_items": n_items})
    return response



def shop(request):

    categorias = Categoria.objects.all()
    linhas = Linha.objects.all()
    produtos = Produto.objects.all()
    cat = request.GET.get('cat', False)
    linha = request.GET.get('linha', False)
    exibindo_cat = 'Todos os produtos'
    exibindo_linha = 'Todas as linhas'
    if cat:
        try:
            exibindo_cat = Categoria.objects.get(pk=cat)
            produtos = produtos.filter(categoria=exibindo_cat)
        except:
            pass
    if linha:
        try:
            exibindo_linha = Linha.objects.get(pk=linha)
            produtos = produtos.filter(linha=exibindo_linha)
        except:
            pass
    if request.is_ajax():
        item = request.GET.get('item')
        quantidade = request.GET.get('qtd')
        dados = add_to_cart(request, prod_id=item, qtd=quantidade)
        return HttpResponse(dados, content_type='application/json')

    return render(request, 'shop/shop.html', {'produtos': produtos, 'categorias': categorias, 'linhas': linhas,
                                              'exibindo_cat': exibindo_cat, 'exibindo_linha': exibindo_linha})


def cart(request):

    lista = list(request.session.get('cart', {}).keys())
    produtos = Produto.objects.filter(pk__in=lista)
    if request.method == 'POST':
        item = request.POST.get('item')
        add_to_cart(request, prod_id=item, qtd=0)
        return HttpResponseRedirect(reverse('cart'))

    if request.is_ajax():
        item = request.GET.get('item')
        quantidade = request.GET.get('qtd')
        dados = add_to_cart(request, prod_id=item, qtd=quantidade)
        return HttpResponse(dados, content_type='application/json')

    return render(request, 'shop/cart.html', {'produtos': produtos})


@login_required
def entrega(request):

    if request.session.get('cart'):
        try:
            instance = Entrega.objects.get(usuario=request.user)
            cep = instance.cep
        except Entrega.DoesNotExist:
            instance = None
            cep = None
        form = EntregaForm(instance=instance)
        if request.is_ajax():
            cep = request.GET.get('cep')
            erro = ""
            try:
                uf = str(Logradouro.objects.get(cep=cep).uf)
                cod_cidade = str(Logradouro.objects.get(cep=cep).cod_cidade.cod_cidade)
                cidade = str(Cidade.objects.get(cod_cidade=cod_cidade))
                cod_bairro = str(Logradouro.objects.get(cep=cep).cod_bairro.cod_bairro)
                bairro = str(Bairro.objects.get(cod_bairro=cod_bairro))
                logradouro = str(Logradouro.objects.get(cep=cep).logradouro)
                dados = json.dumps({"uf": uf,
                                    "cidade": cidade,
                                    "bairro": bairro,
                                    "logradouro": logradouro,
                                    "erro": erro})
            except:
                dados = json.dumps({"erro": "ERRO"})
            return HttpResponse(dados, content_type='application/json')
        if request.method == "POST":
            form = EntregaForm(request.POST, instance=instance)
            if form.is_valid():
                new_form = form.save(commit=False)
                new_form.usuario = request.user
                new_form.cep = Logradouro.objects.get(cep=request.POST.get('cep'))
                new_form.save()
                return HttpResponseRedirect(reverse('pagamento'))
        return render(request, 'shop/entrega.html', {'form': form, 'cep': cep})
    else:
        return HttpResponseRedirect(reverse('cart'))



@login_required
def pagamento(request):

    if request.session.get('cart'):
        try:
            instance = Entrega.objects.get(usuario=request.user)
            if request.method == "POST":
                pedido = Pedido(entrega=Entrega.objects.get(usuario=request.user))
                pedido.save()
                request.session['pedido'] = pedido.pk
                cart = request.session.get('cart')
                for key, values in cart.items():
                    produto = Produto.objects.get(pk=key)
                    preco = produto.preco
                    qtd = cart[key]
                    ped = Pedido.objects.get(pk=pedido.pk)
                    PedidoItem.objects.create(produto=produto, quantidade=qtd, preco=preco, pedido=ped)
                return HttpResponseRedirect(reverse('finalizar'))
        except Entrega.DoesNotExist:
            return HttpResponseRedirect(reverse('home'))
        return render(request, 'shop/pagamento.html', {'instance': instance})
    else:
        return HttpResponseRedirect(reverse('cart'))


@login_required
def finalizar(request):

    request.session['cart'] = {}
    request.session['preco_total'] = {}
    request.session['n_items'] = {}
    pedido = Pedido.objects.get(pk=request.session.get('pedido'))
    data_entrega = pedido.data + datetime.timedelta(days=10)
    itens = PedidoItem.objects.filter(pedido=pedido)
    n_items = 0
    for i in itens:
        n_items += i.quantidade
    return render(request, 'shop/finalizado.html', {'pedido': pedido, 'data_entrega': data_entrega, 'itens': itens,
                                                    'n_items': n_items})
